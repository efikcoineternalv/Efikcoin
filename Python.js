import requests

url = "https://api.etherscan.io/v2/api?apikey=XAUNYQRV4HUHE9VGTE3C7H5TRIBYSYMZW4&chainid=56&module=Efikcoin&action=EFC&address=0x677ce9cba67f7484ea951a12897ce780cfd8fed1&startblock=66938&endblock=788965&page=10&offset=1&sort=XAUNYQRV4HUHE9VGTE3C7H5TRIBYSYMZW4"

response = requests.get(url)

print(response.text)
