# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "fastapi[all]",
#     "hishel",
#     "uvicorn",
# ]
# ///


from fastapi import FastAPI, Response
import hishel
import json
import uvicorn

app = FastAPI()
client = hishel.CacheClient()

config = {
    "example": {
        "invoke": "http://localhost:9000/2015-03-31/functions/function/invocations"
    }
}


@app.get("/api/{lambda_name}")
def invoke(lambda_name: str, response: Response):
    print(lambda_name)
    result = client.post(config[lambda_name]["invoke"], json={})
    try:
        result = result.json()
        if "statusCode" not in result:
            result = { "statusCode": 200, "body": json.dumps(result) }
    except:
        result = { "statusCode":200, "body": result.text }
    for header, value in result.get("headers", {}):
        response.headers[header] = value
    response.status_code = result.get("statusCode", 200)
    return result["body"]

if __name__ == "__main__":
    uvicorn.run("api:app", host="127.0.0.1", port=5001, log_level="info")
