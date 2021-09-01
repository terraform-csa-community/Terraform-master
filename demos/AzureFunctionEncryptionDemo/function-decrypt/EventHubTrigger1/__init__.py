import time
from typing import List
import logging
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient, EncryptionAlgorithm
from cryptography.fernet import Fernet
import base64

# In-memory cache, public/global variables
crypto_client_cache = None


def main(events: List[func.EventHubEvent]):
    start_time = time.time()
    global crypto_client_cache

    # Iterate through each event from Event Hub
    for event in events:
        json_event = json.loads(event.get_body().decode('utf-8'))

        if crypto_client_cache:
            # Our Key Vault crypto client stores the full URL of the key id in it, from that
            # we can extract the key vault URL, key name, and key verison and compare it to
            # what is listed in the event. If there is a match, the key is cached and good to go,
            # if not, we need to connect to Key Vault.

            # Split from format like
            # https://demo-ggg08m4e59-kv.vault.azure.net/keys/cmk/ba4c5501eba74a29bd67c2f5d530ff80
            key_vault_details = crypto_client_cache.key_id.split('/')
            key_vault_url = f'https://{key_vault_details[2]}/'
            key_name = key_vault_details[4]
            key_version = key_vault_details[5]

            # If the key details don't match what we have in cache, then erase the cache
            if key_vault_url != json_event['key_vault_url'] or key_name != json_event['key_name'] or key_version != \
                    json_event['key_version']:
                crypto_client_cache = None

        if not crypto_client_cache:
            # Cache was either not present or we erased it from above
            # Get key details from Key Vault
            credential = DefaultAzureCredential()
            key_client = KeyClient(vault_url=json_event['key_vault_url'], credential=credential)
            key = key_client.get_key(name=json_event['key_name'], version=json_event['key_version'])
            crypto_client_cache = CryptographyClient(key, credential=credential)

        # Decode the encrypted ciphertext version of our content encryption key (CEK) to get the actual CEK
        cek_bytes = base64.b64decode(bytes(json_event['cek_ciphertext'], 'utf-8'))
        cek = crypto_client_cache.decrypt(EncryptionAlgorithm.rsa_oaep, cek_bytes).plaintext.decode('utf-8')

        # Decrypt the mock PII data with our CEK
        fernet = Fernet(cek)
        pii_decrypted = fernet.decrypt(bytes(json_event['pii_ciphertext'], 'utf-8'))
        pii_json = json.loads(pii_decrypted.decode('utf-8'))

        # Send PII to Customer REST API, per event, or batch events together
        # .......

    end_time = time.time()
    elapsed_time_ms = (end_time - start_time) * 1000
    logging.info(f'Function success! EventHubTrigger, elapsed time {elapsed_time_ms} (ms), events={len(events)} '
                 f'messages={len(pii_json)}')
