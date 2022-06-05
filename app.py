from email.policy import default
from flask import Flask, render_template, request, redirect, jsonify, url_for
import json
from os import listdir
from os.path import isfile, join
from cte_parser import CTEParser
import re

# start flask app
app = Flask(__name__)

# data files

MODELS = 'static\model'


def check_sql_models():
    return [f.split('.')[0] for f in listdir(MODELS) if isfile(join(MODELS, f)) and f.split('.')[-1] == 'sql']


def get_model(model_name, ftype):
    return "static/model/" + model_name + '.' + ftype


def save_model(model_code, model_name, ftype):
    mfile = open(get_model(model_name, ftype), 'w')
    if ftype == 'sql':
        model_code = re.sub(r'\n{2,}', '\n', model_code)
    mfile.write(model_code)
    mfile.close()
    return True


def parse_error_json():
    return [
        {
            "id": "Parse Error",
            "sql": "PARSE ERROR",
            "cols": [{"name": "error",
                      "sql": "parse error"}]
        }
    ]

# home route


@app.route('/model/<model_name>')
@app.route('/model/<model_name>/<msg>/<status>')
def index(model_name, msg="", status=""):

    model_json = []
    path_to_sql = get_model(model_name, 'sql')
    try:
        model_file = open(path_to_sql, 'r')
    except FileNotFoundError:
        return redirect(url_for('home_page', msg="not_found"))
    model_code = model_file.read()
    model_code = re.sub(r'\n{2,}', '\n', model_code)
    return render_template('index.html',
                           model_name=model_name,
                           model_code=model_code,
                           model_adhoc=model_json,
                           msg=msg,
                           status=status,
                           saved_models=check_sql_models())


@app.route('/submite_new', methods=["GET", "POST"])
def submit_model():
    model_code = request.form['sql_code']
    model_name = request.form['filename']
    model_name = model_name.strip(' ')
    parser = CTEParser(model_code)
    is_success, msg = parser.run()
    print(is_success, msg)
    if is_success:
        status = 'success'
        model_json = json.dumps(parser.model)
    else:
        status = 'error'
        msg = "Encountered Parsing Error. Please check your script and make sure there are no syntax error."
        model_json = json.dumps(parse_error_json())
    save_model(model_code, model_name, 'sql')
    save_model(model_json, model_name, 'json')
    return redirect(url_for('index', model_name=model_name, msg=msg, status=status))


@app.route('/get-model-json/<model_name>', methods=['GET', 'POST'])
def get_json(model_name):
    """
    send data to javascript
    """
    path_to_json = get_model(model_name, 'json')

    with open(path_to_json) as f:
        loaded_json = json.load(f)
    return jsonify(loaded_json)


@app.route('/<msg>')
def home_page(msg="Welcome"):

    if msg == 'not_found':
        msg = 'SQL File Not Found'
    else:
        msg = "Welcome"
    return render_template("home.html", saved_models=check_sql_models(), msg=msg)


if __name__ == '__main__':
    app.run(debug=True, port=5000)
