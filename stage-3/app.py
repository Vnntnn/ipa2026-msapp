import os
from flask import Flask, request, render_template, redirect, url_for
from pymongo import MongoClient, DESCENDING
from bson import ObjectId

app = Flask(__name__)


mongo_uri  = os.environ.get("MONGO_URI")
db_name    = os.environ.get("DB_NAME")


client = MongoClient(mongo_uri)
creds_db = client[db_name]
router_col = creds_db["ssh"]


@app.route('/')
def main():
        all_routers = router_col.find().sort("_id", 1)

        for current_idx, router in enumerate(all_routers, start = 1):
                router_col.update_one(
                        {"_id": router["_id"]}, 
                        {"$set": {"idx": current_idx}}
                )

        return render_template('index.html', data = router_col.find())


@app.route("/add_router", methods=["POST"])
def add_router():
    ip = request.form.get("Router IP:").strip() or None
    username = request.form.get("Username:").strip() or None
    password = request.form.get("Password:").strip() or None

    if not all([ip, username, password]):
        return redirect("/")

    last_router = router_col.find_one(sort = [("idx", DESCENDING)])
    next_idx = (last_router["idx"] + 1) if last_router else 1

    creds = {
        "idx": next_idx,
        "ip": ip,
        "username": username,
        "password": password
    }

    router_col.insert_one(creds)
    return redirect("/")


@app.route("/delete_router/<int:idx>", methods=["POST"])
def delete_router(idx):
        try:
                target_idx = int(idx)
                router_col.delete_one({"idx": target_idx})
                router_col.update_many(
                        {"idx": {"$gt": target_idx}}, 
                        {"$inc": {"idx": -1}}
                )
        except Exception:
                pass

        return redirect(url_for("main"))


if __name__ == "__main__":
        app.run(host = "0.0.0.0", port = 8080)
