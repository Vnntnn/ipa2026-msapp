from flask import Flask
from flask import request
from flask import render_template

sameple = Flask(__name__)

@sameple.route('/')
def main():
        return render_template('index.html')

if __name__ == "__main__":
        sameple.run(host = "0.0.0.0", port = 8080)
