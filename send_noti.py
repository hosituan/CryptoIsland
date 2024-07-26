import requests
import subprocess
import time
import json
import flask
from flask import Flask
app = Flask(__name__)

def fetch_coin_price(symbol):
    base_url = "https://api.binance.com/api/v3/ticker/price"
    response = requests.get(base_url, params={"symbol": symbol})
    response.raise_for_status()  # Raises an HTTPError if the response was an error
    data = response.json()
    return data['price']

import datetime
from datetime import datetime, timedelta
import calendar
import jwt
import json
import os
import jwt
import time
# APNs Auth Key file and credentials
AUTH_KEY_FILE = '/Users/hosituan/Downloads/AuthKey_F5HG5R857T.p8'
TEAM_ID = '4NY95N3V93'
KEY_ID = 'F5HG5R857T'


with open(AUTH_KEY_FILE, 'r') as f:
    secret = f.read()

def getApnToken():
    # Create the JWT
    headers = { "alg": "ES256", "kid": KEY_ID }
    now = calendar.timegm(time.gmtime())
    print(int(now))
    payload = { "iss": TEAM_ID, "iat": int(now) }

    token = jwt.encode(payload, secret, algorithm='ES256', headers=headers)
    print(token)
    return token


apnToken = "eyAiYWxnIjogIkVTMjU2IiwgImtpZCI6ICJGNUhHNVI4NTdUIiB9.eyAiaXNzIjogIjROWTk1TjNWOTMiLCAiaWF0IjogMTcyMTk3NDM2MyB9.MEQCIGNcPGiCufs2BT9Y4b7R-u_psn2esIfhff1LmSVH4ji9AiAguklr6x9U-FdXSFlK4dtZgslFsqRcy5i0SUOdopZliA"

def send_push_notification(token, device_id, symbol, price, is_inscrease):
    # Define the payload with the fetched price
    payload = {
        "aps": {
            "timestamp": int(time.time()),
            "event": "update",
            "content-state": {
                "price": price,
                "symbol": symbol,
                "isIncrease": is_inscrease
            },
            "stale-date": int(time.time()),
            "alert": {
                "title": f"Price Update for {symbol}",
                "body": f"The current price of {symbol} is {price}.",
                "sound": "chime.aiff"
            }
        }
    }
    
    # Convert payload to JSON string
    payload_json = json.dumps(payload)
    
    # Define the curl command with variables
    curl_command = [
        "curl", "-v",
        "--header", f"authorization: bearer {apnToken}",
        "--header", "apns-topic: com.swiftys.com.DynamicPriceIsland.push-type.liveactivity",
        "--header", "apns-push-type: liveactivity",
        "--header", "apns-priority: 10",
        "--header", "apns-expiration: 0",
        "--data", payload_json,
        "--http2",
        f"https://api.development.push.apple.com:443/3/device/{device_id}"
    ]
    
    # Run the curl command
    result = subprocess.run(curl_command, capture_output=True, text=True)
        # Print results
    print("STDOUT:")
    print(result.stdout)
    print("STDERR:")
    print(result.stderr)

def main():
    token = ""
    device_id = "8096462fc0484d0a1ecb57f0c7a2147f77102bd0e93f99406459e73adcba2a3163e8b8da42e5f3d2c3cbd6d447a7a432b15e99f7f25c54acf25be9e2e27cbaa08ec885792601b83b8e0b94bb486eea888791edda7e4fa0dc836b3adc8c487fa55b9955cbf85405560f37a2c15cc9e3b010292e6ccdd863488760b1464a84c9a8"
    symbol = "BTCUSDT"  # Binance uses "BTCUSDT" instead of "BTC/USD"
    last_price = 0
    while True:
        try:
            price = fetch_coin_price(symbol)
            is_inscrease = float(price) >= float(last_price)
            last_price = price
            send_push_notification(token, device_id, symbol, price, is_inscrease)
        except Exception as e:
            print(f"An error occurred: {e}")
        
        time.sleep(5)  # Wait for 1 second before fetching and sending again

if __name__ == "__main__":
    main()
    # getApnToken()
    
