from flask import Flask, request, jsonify
import time

app = Flask(__name__)

turtles = {}

OFFLINE_AFTER_SECONDS = 30

@app.post("/status")
def updateStatus():
    data = request.get_json(force=True)
    
    turtle_id = str(data.get("id"))
    
    if not turtle_id or turtle_id == "None":
        return {"ok": False, "message": "Missing turtle ID"}, 400
    
    turtles[turtle_id] = {
        "id": turtle_id,
        "label": data.get("label"),
        "status": data.get("status", "unknown"),
        "mode": data.get("mode", "unknown"),
        "fuel": data.get("fuel"),
        "steps_from_base": data.get("steps_from_base"),
        "message": data.get("message", ""),
        "last_seen": time.time()
    }
    
    return {"ok": True, "turtle": turtles[turtle_id]}

@app.get("/turtles")
def getTurtles():
    now = time.time()
    result = {}
    
    for turtle_id, data in turtles.items():
        age = now - data["last_seen"]
        
        result[turtle_id] = {
            **data,
            "age_seconds": round(age),
            "online": age <= OFFLINE_AFTER_SECONDS
        }

    return jsonify(result)

@app.get("/")
def home():
    return {
        "message": "Turtle monitor backend is running",
        "endpoints": ["/status", "/turtles"]
    }
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)