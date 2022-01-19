import cx_Oracle
import csv 

dsn_tns = cx_Oracle.makedsn('IP_ADDRESS_HostOracle', 'PORT', service_name='DB-NAME')
conn = cx_Oracle.connect(user='USER', password='PASSWD', dsn=dsn_tns)

f=open('d:\\Bash\\python-cx_Oracle\\test.txt', 'a')

c = conn.cursor()
c.execute('SELECT * FROM customers')
for row in c:
    print (row[0], '-', row[1], '-', row[2], '-', row[3], '-', row[4])
    f.write(str(row) + "\n")
conn.close()