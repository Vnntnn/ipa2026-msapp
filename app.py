from flask import Flask
from flask import request
from flask import render_template
from flask import redirect

app = Flask(__name__)

data = []

@app.route('/')
def main():
        return render_template('index.html', data = data)

@app.route("/add", methods = ["POST"])
def add_comment():
        yourname = request.form.get("yourname")
        message = request.form.get("message")
        
        if not yourname and not message:
               return redirect("/")

        data.append({
                "yourname": yourname,
                "message": message
        })

        return redirect("/")

if __name__ == "__main__":
        app.run(host = "0.0.0.0", port = 8080)
