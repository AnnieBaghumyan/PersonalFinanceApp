# PersonalFinanceApp

Personal Finance Management App

[ERD](https://lucid.app/lucidchart/6d8337f9-f7ab-4687-a7c9-dcd00740d745/edit?invitationId=inv_d1cdf60c-aba6-4fa5-9cf0-659a915c6706&page=0_0#)

### How to run the demo app

Before running the demo app make sure that:

1. the psycopg2-binary is installed:

        pip install psycopg2-binary

2. then make sure the DB exists and is populated:

    * Run your DDL (ddl.sql)
    * Run your DML (dml.sql)
   
3. update the config at the top:

          DB_NAME = "pfms"
          DB_USER = "postgres"
          DB_PASSWORD = "your_password_here"
          DB_HOST = "localhost"
          DB_PORT = 5432

4. run:

         python pfms_demo.py

### How to run the full app

1. Database

   * Create DB pfms in PostgreSQL.
   
   * Run your DDL (phase4_schema.sql).
   
   * Run your DML (phase4_data.sql).

2. Backend

   * Put app.py in a folder.
   
          pip install flask flask-cors psycopg2-binary
   
   * Update DB credentials at the top of app.py.
   
   * Run: 
     
          python app.py

3. Frontend

   * Save the HTML as index.html.
   
   * Just open it in your browser (double click or Ctrl+O → open file).
   
   * It will call http://localhost:5000/api/... endpoints.