from flask import Flask, request, render_template, redirect, url_for
from pymongo import MongoClient, DESCENDING
from bson import ObjectId

app = Flask(__name__)

client = MongoClient("mongodb://mongo:27017/")
creds_db = client["RouterCreds"]
router_col = creds_db["ssh"]


@app.route('/')
def main():
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
                router_col.delete_one({"idx": idx})
        except Exception:
                pass

        return redirect(url_for("main"))


if __name__ == "__main__":
        app.run(host = "0.0.0.0", port = 8080)
