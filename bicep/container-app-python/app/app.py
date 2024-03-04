from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({"response": "OK", "code": 200})

@app.route('/info', methods=['GET'])
def get_server_ip():
    import psycopg2
    import os
    import re

    response = "no server data found..."

    try:
        # get env var
        DB_CXN_STR = os.getenv('DB_CONNECTION_STRING')

        # connect to db server
        conn = psycopg2.connect(DB_CXN_STR)
        cursor = conn.cursor()

        # get database server ip address
        cursor.execute("SELECT inet_server_addr FROM inet_server_addr();")
        row = cursor.fetchall()
        serverIp = str(row[0])

        ip = re.sub('[\'(),]', '', serverIp)
        response =  "Connected to Database Server IP: " + ip + " cxn string: " + DB_CXN_STR
        return response

    except Exception as err:
        return("error: (" + err  + ") connecting to database with connection string: " + DB_CXN_STR)
    finally:
        # dispose
        conn.commit()
        cursor.close()
        conn.close()
        
        return response

if __name__ == '__main__':
    app.run(debug=True)
