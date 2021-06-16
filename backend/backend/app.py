from flask import Flask, render_template , request , jsonify, redirect
import os , io , sys
import base64
import sqlite3
from sqlite3 import Error



app = Flask(__name__)


@app.route('/register',methods=['GET','POST'])
def registerWithBank():
    conn = sqlite3.connect("db.db")
    print(sqlite3.version)
    c = conn.cursor()
    f = request.form
    c.execute("UPDATE customer SET uniqID=?, photo=? WHERE accountnumber=?", (f["data"], f["binaryimage"], f["accountnumber"]))
    conn.commit()
    conn.close()


    return "success"

@app.route('/verify',methods=['GET','POST'])
def verifyImage():
    print(request.form)
    conn = sqlite3.connect("db.db")
    c = conn.cursor()
    f = request.form
    c.execute("SELECT amount_balance FROM customer WHERE accountnumber=? AND uniqID=?", (f["accountnumber"],f["uniqCode"]))
    index_table = c.fetchall()
    conn.close()
    print(index_table)
    if len(index_table)>0:
        return str(index_table[0][0])
    else:
        return "failure"

@app.route('/approve',methods=['GET','POST'])
def approve():
    conn = sqlite3.connect("db.db")
    c = conn.cursor()
    f = request.args
    c.execute("UPDATE customer SET approved=1 WHERE accountnumber=?", (f["accountnumber"],))
    conn.commit()
    conn.close()
    return redirect("view", code=302)



@app.route('/view',methods=['GET','POST'])
def viewCustomers():
    conn = sqlite3.connect("db.db")
    c = conn.cursor()
    c.execute("SELECT * FROM customer WHERE approved=0 AND uniqID IS NOT ''")
    index_table = c.fetchall()
    conn.close()
    return render_template("view.html", index_table=index_table)


if __name__ == '__main__':
    app.run(debug=True, host= '0.0.0.0')
