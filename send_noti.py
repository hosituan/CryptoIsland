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
        "--header", f"authorization: bearer {token}",
        "--header", "apns-topic: com.swiftys.com.DynamicPriceIsland.push-type.liveactivity",
        "--header", "apns-push-type: liveactivity",
        "--header", "apns-priority: 10",
        "--header", "apns-expiration: 0",
        "--data", payload_json,
        "--http2",
        f"https://api.development.push.apple.com:443/3/device/{device_id}"
    ]
    
    # Run the curl command
    subprocess.run(curl_command, capture_output=True, text=True)

def main():
    token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiIsImtpZCI6IkY1SEc1Ujg1N1QifQ.eyJpc3MiOiI0Tlk5NU4zVjkzIiwiaWF0IjoxNzIxOTIwNTQ5LjYwNDY5Mn0.uSw0d93IPEaBiZ5z6LXl6Cpni2U1KcbM51GJUhjPliJHqShEGNaXaybvQqZC9tyrq6bmcd2Xqvr_P4q20CyMBg"
    device_id = "80a25d643e7f492d52a1a35b34de52c7fbc36871f034308704b0487a814e48e36d1861782067a54ab57e7fb49069c207e00343de97b41db4b1b38f0e3ac297126c5cda1cfea855350e9be91eccb788a44a858c8aceba3898b70b8149c653526d0205c0af1edc7bfac91cd2bfa425b14f939592cd64d280a9f123e570f0257619"
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
        
        time.sleep(1)  # Wait for 1 second before fetching and sending again

if __name__ == "__main__":
    main()
    