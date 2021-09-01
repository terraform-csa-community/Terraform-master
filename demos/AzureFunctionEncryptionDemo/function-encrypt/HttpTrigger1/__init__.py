import os
import time
import logging
import json
import base64
import logging
from faker import Faker
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient, EncryptionAlgorithm
from cryptography.fernet import Fernet
import asyncio
from azure.eventhub.aio import EventHubProducerClient
from azure.eventhub import EventData

# In-memory cache, public/global variables
key_vault_cache = None
cek = None
cek_ciphertext = None


def main(req: func.HttpRequest) -> func.HttpResponse:
    # Track execution time
    start_time = time.time()

    # Validate required environment variables are provided
    required_env_variables = ['KEY_VAULT_URL', 'KEY_NAME', 'KEY_VERSION', 'AZURE_CLIENT_ID',
                              'EVENTHUB_CONNECTION_STRING', 'EVENTHUB_NAME']

    for env_variable in required_env_variables:
        if not os.environ.get(env_variable):
            return func.HttpResponse(
                f'Function not configured correctly and missing a environment variable value for "{env_variable}"',
                status_code=400)

    # Validate event_count was provided in the query string params
    event_count = req.params.get('event_count')
    if not event_count:
        return func.HttpResponse(
            'Function executed but an event count was not provided, please provide "event_count" in the query string ',
            status_code=400)
    else:
        event_count = int(event_count)

    # Optional batch_count param
    batch_count = req.params.get('batch_count')
    if not batch_count:
        batch_count = 1
    else:
        batch_count = int(batch_count)

    # Initialize our key vault client, either from memory or connect to Key Vault
    key_vault_cache_status = initialize_key_vault_client()

    message_batch = []
    plain_text_mock_pii_data = []
    for i in range(batch_count):
        # Form the structure of our business event message
        event_message = {'api_endpoint': 'https://mockapi.localhost/submit',
                         'pii_ciphertext': None,
                         'key_vault_url': os.environ['KEY_VAULT_URL'],
                         'key_name': os.environ['KEY_NAME'],
                         'key_version': os.environ['KEY_VERSION']
                         }

        # Generate Mock PII data    
        mock_pii_data = generate_mock_pii_data(event_count)
        plain_text_mock_pii_data.append(mock_pii_data)

        # Encrypt the mock PII data, store it and the CEK in our event message
        event_message['cek_ciphertext'], event_message['pii_ciphertext'] = encrypt_mock_pii_data(mock_pii_data)

        # Create a Async lopp to send our event to EventHub
        try:
            loop = asyncio.get_event_loop()
        except:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)

        # Send our event to EventHub
        try:
            loop.run_until_complete(send_data_to_eventhub(json.dumps(event_message)))
        except Exception as e:
            return func.HttpResponse(f'Exception sending data to EventHub with exception: {e}', status_code=400)

        message_batch.append(event_message)

    # Return status output back to the client
    end_time = time.time()
    elapsed_time_ms = (end_time - start_time) * 1000
    logging.info(
        f'Function success! HTTPTrigger, elapsed time {elapsed_time_ms} (ms), sent events={len(mock_pii_data)}')

    return func.HttpResponse(
        f'HTTP triggered function executed successfully.\n\n'
        f'Event count={event_count}\n'
        f'Batch count={batch_count}\n'
        f'Total data size={len(json.dumps(message_batch)) / 1024} KB\n'
        f'Elasped execution time={elapsed_time_ms} milloseconds \n'
        f'Cache status = {key_vault_cache_status}\n\n'
        f'message_batch =\n\n'
        f'{json.dumps(message_batch, indent=2)}\n\n'
        f'plaintext mock_pii_data = \n\n {json.dumps(plain_text_mock_pii_data, indent=2)}')


def initialize_key_vault_client():
    # Initialize Key Vault Client or use it from the cache
    global key_vault_cache
    cache_status = ''

    if not key_vault_cache:
        # Key Vault data was cached
        cache_status = 'Key Vault client was not cached. '
    elif key_vault_cache and key_vault_cache['key_vault_url'] != os.environ['KEY_VAULT_URL'] or key_vault_cache[
        'key_name'] != os.environ['KEY_NAME'] or key_vault_cache['key_version'] != os.environ['KEY_VERSION']:
        # Key Vault data was cached, but URL, key, or key version has changed
        key_vault_cache = None
        cache_status = 'Key Vault client was previously cached, but Vault URI, Key name, or Key version was changed '
    else:
        cache_status = 'Key Vault client was previously cached'

    if not key_vault_cache:
        # Get data from Key Vault
        key_vault_cache = {'key_vault_url': os.environ['KEY_VAULT_URL'],
                           'key_name': os.environ['KEY_NAME'],
                           'key_version': os.environ['KEY_VERSION'],
                           'crypto_client': None
                           }

        cache_status += 'Getting new data from KeyVault'

        # https://docs.microsoft.com/en-us/python/api/overview/azure/identity-readme?view=azure-python#specifying-a-user-assigned-managed-identity-for-defaultazurecredential
        credential = DefaultAzureCredential()
        key_client = KeyClient(vault_url=key_vault_cache['key_vault_url'], credential=credential)
        key = key_client.get_key(name=key_vault_cache['key_name'], version=key_vault_cache['key_version'])

        key_vault_cache['crypto_client'] = CryptographyClient(key, credential=credential)

    return cache_status

def generate_mock_pii_data(count):
    # Uses the Faker module to generate mock PII data and return a list [] of entries
    fake = Faker()
    mock_pii_data = []

    for i in range(count):
        mock_person = {'name': fake.name(),
                       'address': fake.address(),
                       'ssn': fake.ssn(),
                       'phone': fake.phone_number(),
                       'bban': fake.bban(),
                       'swift': fake.swift(),
                       'aba': fake.aba(),
                       'iban': fake.iban(),
                       'credit_card_number': fake.credit_card_number(),
                       'credit_card_provider': fake.credit_card_provider(),
                       'credit_card_expire': fake.credit_card_expire(),
                       'credit_card_security_code': fake.credit_card_security_code()
                       }

        mock_pii_data.append(mock_person)

    return mock_pii_data

def encrypt_mock_pii_data(data):
    mock_pii_data_bytes = bytes(json.dumps(data), 'utf-8')

    # https://docs.microsoft.com/en-us/azure/key-vault/keys/about-keys-details
    # https://docs.microsoft.com/en-us/python/api/azure-keyvault-keys/azure.keyvault.keys.crypto.cryptographyclient
    # Symmetric key algorithms are only supported by Managed HSM

    # Create a symmetric content encryption key (CEK), AES in CBC mode 128-bit key using PKCS7 for padding, HMAC with SHA256
    # Output will be Base64 encoded key
    # https://cryptography.io/en/latest/fernet/
    global cek
    global cek_ciphertext
    global key_vault_cache

    if not cek:
        # If key is not cached in memory, create a new key, store in memory, and encrypt it using KeyVault
        cek = Fernet.generate_key()

        cek_cipher_text_bytes = key_vault_cache['crypto_client'].encrypt(EncryptionAlgorithm.rsa_oaep, cek).ciphertext
        cek_ciphertext = base64.b64encode(cek_cipher_text_bytes).decode('utf-8')

    # Encrypt our mock PII data with the key. The result will be Base64 encoded bytes, convert it to a string
    fernet = Fernet(cek)
    mock_pii_data_cipher_text_bytes = fernet.encrypt(mock_pii_data_bytes)
    pii_ciphertext = mock_pii_data_cipher_text_bytes.decode('utf-8')

    return cek_ciphertext, pii_ciphertext

async def send_data_to_eventhub(data):
    # https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-python-get-started-send
    # Create a producer client to send messages to the event hub.
    # Specify a connection string to your event hubs namespace and
    # the event hub name.

    # Maximum size of Event Hubs publication is 1MB per single event or a batch
    if len(data) > 1013760:
        # Raise an error if the data is 990 KB or larger (to account for some wiggle room)
        raise Exception(
            f'Error: Data size is {len(data) / 1024} KB and is close or above the 1 MB limit, a single event or batch of events must be 1 MB or less')

    producer = EventHubProducerClient.from_connection_string(conn_str=os.environ['EVENTHUB_CONNECTION_STRING'],
                                                             eventhub_name=os.environ['EVENTHUB_NAME'])
    async with producer:
        # Create a batch.
        event_data_batch = await producer.create_batch()

        # Add events to the batch.
        event_data_batch.add(EventData(data))

        # Send the batch of events to the event hub.
        await producer.send_batch(event_data_batch)
