import subprocess
import os

# APNs Auth Key file and credentials
AUTH_KEY_FILE = '/Users/hosituan/Downloads/AuthKey_F5HG5R857T.p8'
TEAM_ID = '4NY95N3V93'
KEY_ID = 'F5HG5R857T'

# Environment variables
os.environ['AUTH_KEY_ID'] = KEY_ID
os.environ['TEAM_ID'] = TEAM_ID
os.environ['TOKEN_KEY_FILE_NAME'] = AUTH_KEY_FILE

# Get the current Unix timestamp
JWT_ISSUE_TIME = subprocess.check_output(['date', '+%s']).decode('utf-8').strip()

# Create JWT header
JWT_HEADER = subprocess.check_output([
    'printf', '{ "alg": "ES256", "kid": "%s" }' % KEY_ID
]).decode('utf-8').strip()

JWT_HEADER = subprocess.check_output([
    'echo', JWT_HEADER
]).decode('utf-8').strip()

JWT_HEADER = subprocess.check_output([
    'echo', JWT_HEADER,
    '|', 'openssl', 'base64', '-e', '-A',
    '|', 'tr', '--', '+/', '-_',
    '|', 'tr', '-d', '='
], shell=True).decode('utf-8').strip()

# Create JWT claims
JWT_CLAIMS = subprocess.check_output([
    'printf', '{ "iss": "%s", "iat": %d }' % (TEAM_ID, int(JWT_ISSUE_TIME))
]).decode('utf-8').strip()

JWT_CLAIMS = subprocess.check_output([
    'echo', JWT_CLAIMS,
    '|', 'openssl', 'base64', '-e', '-A',
    '|', 'tr', '--', '+/', '-_',
    '|', 'tr', '-d', '='
], shell=True).decode('utf-8').strip()

# Concatenate JWT header and claims
JWT_HEADER_CLAIMS = f"{JWT_HEADER}.{JWT_CLAIMS}"

# Sign the header and claims
JWT_SIGNED_HEADER_CLAIMS = subprocess.check_output([
    'printf', JWT_HEADER_CLAIMS,
    '|', 'openssl', 'dgst', '-binary', '-sha256', '-sign', AUTH_KEY_FILE,
    '|', 'openssl', 'base64', '-e', '-A',
    '|', 'tr', '--', '+/', '-_',
    '|', 'tr', '-d', '='
], shell=True).decode('utf-8').strip()

# Create the final JWT token
AUTHENTICATION_TOKEN = f"{JWT_HEADER}.{JWT_CLAIMS}.{JWT_SIGNED_HEADER_CLAIMS}"

print(AUTHENTICATION_TOKEN)
