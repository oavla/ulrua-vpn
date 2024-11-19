from flask import Flask, request, render_template, redirect
import requests

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/search', methods=['GET'])
def search():
    query = request.args.get('q')
    if not query:
        return redirect('/')
    url = f"https://duckduckgo.com/?q={query}"
    response = requests.get(url)
    return response.content, response.status_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
