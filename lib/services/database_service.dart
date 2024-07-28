import 'dart:convert';

import 'package:mobilepos_beta/variable/hostaddress.dart';
import 'package:mobilepos_beta/variable/receiptdata.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:mobilepos_beta/variable/status.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  // Declaring database variable called _db
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  // Configuration Table
  final String _configtable = "configuration";
  final String _configid = "id";
  final String _configtoken = "token";

  //issued_tickets Table
  final String _issuedticketstable = "issued_tickets";
  final String _issuedticketsid = "id";
  final String _issuedticketsnumber = "ticket_number";
  final String _issuedticketsplatenumber = "plate_number";
  final String _issuedticketstimein = "time_in";
  final String _issuedticketstimeout = "time_out";
  final String _issuedticketshours = "hours";
  final String _issuedticketstotal = "total";
  final String _issuedticketsstatus = "status";
  final String ticketstatus = "pending";
  final String _ticketapistatus = "api";

  //toilet_receipt Table
  final String _toiletreceipttable = "toilet_receipt";
  final String _toiletreceiptid = "id";
  final String _toiletreceiptprice = "price";
  final String _toiletreceipttime = "time";
  final String _toiletapistatus = "status";

  //ticket_details
  final String _ticket_detailstable = "ticket_details";
  final String _ticket_detailsid = "id";
  final String _ticket_detailtitle = "title";
  final String _ticket_detailstoilet_title = "toilet_title";
  final String _ticket_detailscompany_name = "company_name";
  final String _ticket_detailscompany_address = "company_address";
  final String _ticket_detailsfooter = "footer";

  //mobilepos_configurations
  final String _mobilepos_configurationtable = "mobilepos_configuration";
  final String _mobilepos_configurationid = "id";
  final String _mobilepos_configurationparkingrate = "parking_rate";
  final String _mobilepos_configurationtoiletrate = "toilet_rate";
  final String _mobilepos_configurationapi = "api";


  DatabaseService._constructor();

  // Give access to database
  Future<Database> get database async {
    // If not null, then return the database
    if (_db != null) return _db!;

    // If null, getdatabase
    _db = await getdatabase();
    return _db!;
  }

  Future<Database> getdatabase() async {
    final databaseDirPath = await getDatabasesPath();
    // Declaring database path, from path library and can name the db itself .db
    final databasePath = join(databaseDirPath, "application_db.db");

    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {

        await db.execute('''
      CREATE TABLE IF NOT EXISTS $_configtable (
      $_configid INTEGER PRIMARY KEY AUTOINCREMENT,
      $_configtoken TEXT NOT NULL
      )
    ''');

        await db.execute('''
      CREATE TABLE IF NOT EXISTS $_mobilepos_configurationtable (
      $_mobilepos_configurationid INTEGER PRIMARY KEY AUTOINCREMENT,
      $_mobilepos_configurationparkingrate TEXT NOT NULL,
      $_mobilepos_configurationtoiletrate TEXT NOT NULL
      )
    ''');

        await db.execute('''
      CREATE TABLE IF NOT EXISTS $_ticket_detailstable (
      $_ticket_detailsid INTEGER PRIMARY KEY AUTOINCREMENT,
      $_ticket_detailtitle TEXT NOT NULL,
      $_ticket_detailstoilet_title TEXT NOT NULL,
      $_ticket_detailscompany_name TEXT NOT NULL,
      $_ticket_detailscompany_address TEXT NOT NULL,
      $_ticket_detailsfooter TEXT NOT NULL
      )
    ''');

        await db.execute('''
      CREATE TABLE IF NOT EXISTS $_issuedticketstable (
      $_issuedticketsid INTEGER PRIMARY KEY AUTOINCREMENT,
      $_issuedticketsnumber TEXT NOT NULL,
      $_issuedticketsplatenumber TEXT NOT NULL,
      $_issuedticketstimein TEXT NOT NULL,
      $_issuedticketstimeout TEXT NOT NULL,
      $_issuedticketshours TEXT NOT NULL,
      $_issuedticketstotal TEXT NOT NULL,
      $_issuedticketsstatus TEXT NOT NULL,
      $_ticketapistatus TEXT NOT NULL
      )
    ''');

        await db.execute('''
      CREATE TABLE IF NOT EXISTS $_toiletreceipttable (
      $_toiletreceiptid INTEGER PRIMARY KEY AUTOINCREMENT,
      $_toiletreceiptprice TEXT NOT NULL,
      $_toiletreceipttime TEXT NOT NULL,
      $_toiletapistatus TEXT NOT NULL
      )
    ''');

        // Check if there are any existing records in _configtable
        List<Map<String, dynamic>> configRecords = await db.query(_configtable);
        if (configRecords.isEmpty) {
          await db.insert(
            _configtable,
            {
              _configid: 1,
              _configtoken: '',
            },
          );
        }

        // Check if there are any existing records in _ticket_detailstable
        List<Map<String, dynamic>> ticketDetailsRecords = await db.query(_ticket_detailstable);
        if (ticketDetailsRecords.isEmpty) {
          await db.insert(
            _ticket_detailstable,
            {
              _ticket_detailsid: 1,
              _ticket_detailtitle: '',
              _ticket_detailstoilet_title: '',
              _ticket_detailscompany_name: '',
              _ticket_detailscompany_address: '',
              _ticket_detailsfooter: ''
            },
          );
        }

        // Check if there are any existing records in _mobilepos_configurationtable
        List<Map<String, dynamic>> mobilePosConfigRecords = await db.query(_mobilepos_configurationtable);
        if (mobilePosConfigRecords.isEmpty) {
          await db.insert(
            _mobilepos_configurationtable,
            {
              _mobilepos_configurationid: 1,
              _mobilepos_configurationparkingrate: '',
              _mobilepos_configurationtoiletrate: '',
            },
          );
        }
      },
    );


    // Return variable database
    return database;
  }

  Future <String> checktoken() async
  {
    final db = await database;
    List<Map> list = await db.rawQuery('SELECT * FROM $_configtable WHERE $_configid = 1');

    String check = list[0]['token'];
    print(list[0]['token']);
    status = list[0]['token'];

    if(check == "")
      {
        return "404";
      }

    else
      {
        return "200";
      }

  }

  Future <String> assigntoken() async
  {
    final db = await database;
    List<Map> list = await db.rawQuery('SELECT * FROM $_configtable WHERE $_configid = 1');

    token = await list[0]['token'];

    if(token!= "")
      {
        return "200";
      }
    else
      {
        return "404";
      }

  }

  void storetoken(String content) async {

    // To access the database itself
    final db = await database;

    // Actual insert query to insert data in database

    Map<String, dynamic> values = {
      _configtoken: content,
    };

    await db.update(_configtable, values,
    where: 'id = ?',
    whereArgs: [1]);

    token = values[_configtoken];
    print(token);

    /*
    await db.insert(
      _configtable,
      {
        _configid: 1,
        _configtoken: content,
      },
    );

     */

    // Query and print the updated table
    final List<Map<String, dynamic>> updatedTable = await db.query(_configtable);

    /*
    updatedTable.forEach((row) {
      print(row);
    });

    print(updatedTable);

     */


  }

  void deletetoken() async
  {
    // To access the database itself
    final db = await database;

    // Actual insert query to insert data in database

    Map<String, dynamic> values = {
      _configtoken: "",
    };

    await db.update(_configtable, values,
        where: 'id = ?',
        whereArgs: [1]);

    final List<Map<String, dynamic>> updatedTable = await db.query(_configtable);

    token = updatedTable[0][_configtoken];
    print(token);
  }

  void fetchticketandconfiguration() async
  {
    final db = await database;

    List<Map> assignticketdetails = await db.rawQuery('SELECT * FROM $_ticket_detailstable WHERE $_ticket_detailsid = 1');
    List<Map> assignpricing = await db.rawQuery('SELECT * FROM $_mobilepos_configurationtable WHERE $_mobilepos_configurationid = 1');


    receipt_title = await assignticketdetails[0]['title'];
    toilet_title = await assignticketdetails[0]['toilet_title'];
    company_name = await assignticketdetails[0]['company_name'];
    company_address= await assignticketdetails[0]['company_address'];
    footer = await assignticketdetails[0]['footer'];

    parking_rate = await assignpricing[0]['parking_rate'];
    toilet_price = await assignpricing[0]['toilet_rate'];

  }


  Future<String> storeticketdetails(
      String? title,
      String? toilettitle,
      String? companyname,
      String? companyaddress,
      String? footers,
      String? parkingrate,
      String? toiletprice,
      List pending_data,
      ) async {
    final db = await database;

    Map<String, dynamic> values = {
      _ticket_detailtitle: title,
      _ticket_detailstoilet_title: toilettitle,
      _ticket_detailscompany_name: companyname,
      _ticket_detailscompany_address: companyaddress,
      _ticket_detailsfooter: footers,
    };

    Map<String, dynamic> values1 = {
      _mobilepos_configurationparkingrate: parkingrate,
      _mobilepos_configurationtoiletrate: toiletprice,
    };

    // Perform the update and get the number of affected rows
    int count = await db.update(
      _mobilepos_configurationtable,
      values1,
      where: 'id = ?',
      whereArgs: [1],
    );

    int count1 = await db.update(
      _ticket_detailstable,
      values,
      where: 'id = ?',
      whereArgs: [1],
    );

    // Check if the update was successful
    if (count > 0 && count1 > 0) {
      final List<Map<String, dynamic>> updatedTable = await db.query(_ticket_detailstable);
      final List<Map<String, dynamic>> updatedTable1 = await db.query(_mobilepos_configurationtable);

      receipt_title = await updatedTable[0]['title'];
      toilet_title = await updatedTable[0]['toilet_title'];
      company_name = await updatedTable[0]['company_name'];
      company_address = await updatedTable[0]['company_address'];
      footer = await updatedTable[0]['footer'];

      parking_rate = await updatedTable1[0]['parking_rate'];
      toilet_price = await updatedTable1[0]['toilet_rate'];

      updatedTable.forEach((row) {
        print(row);
      });

      print(updatedTable);

      // Get the list of pending but uploaded tickets
      final List<Map<String, dynamic>> checkdatabase = await db.query(
        _issuedticketstable,
        where: '$_ticketapistatus = ? AND $_issuedticketsstatus = ?',
        whereArgs: ['200', 'pending'],
      );

      print("LIST OF PENDING BUT UPLOADED");
      print(checkdatabase);
      print("LIST OF PENDING DATA FROM THE ONLINE DATABASE");
      print(pending_data);

      // Insert only non-existing pending data into _issuedticketstable
      for (var pendingItem in pending_data) {
        bool exists = checkdatabase.any((dbItem) =>
        dbItem['ticket_number'] == pendingItem['ticket_number'] &&
            dbItem['plate_number'] == pendingItem['plate_number'] &&
            dbItem['time_in'] == pendingItem['time-in']
        );

        if (!exists) {
          await db.insert(_issuedticketstable, {
            'ticket_number': pendingItem['ticket_number'],
            'plate_number': pendingItem['plate_number'],
            'time_in': pendingItem['time-in'],
            'time_out': '',
            'hours': '',
            'total': '',
            'status': pendingItem['status'],
            'api': '200',
          });
        }
      }

      return "200";
    } else {
      return "404";
    }
  }


  Future <String> insert_issued_tickets(String platenumber, String timein) async
  {
    final db = await database;

    final List<Map<String, dynamic>> checkdatabase = await db.query(
        _issuedticketstable,
        where: '$_issuedticketsplatenumber = ? AND $_issuedticketsstatus = ?',
        whereArgs: [platenumber, 'pending']
    );

    if(checkdatabase.isEmpty)
      {
        int id = await db.insert(
          _issuedticketstable,
          {
            _issuedticketsnumber: '',
            _issuedticketsplatenumber: platenumber,
            _issuedticketstimein: timein,
            _issuedticketstimeout: '',
            _issuedticketshours: '',
            _issuedticketstotal: '',
            _issuedticketsstatus: ticketstatus,
            _ticketapistatus: '404'
          },
        );

        if (id > 0) {
          Map<String, dynamic> values = {
            _issuedticketsnumber: 'TKT-000$id',
          };

          await db.update(_issuedticketstable, values,
              where: '$_issuedticketsplatenumber = ? AND $_issuedticketsstatus = ?',
              whereArgs: [platenumber, 'pending']);

          final List<Map<String, dynamic>> updatedTable = await db.query(
              _issuedticketstable,
              where: '$_issuedticketsplatenumber = ? AND $_issuedticketsstatus = ?',
              whereArgs: [platenumber, 'pending']
          );

          ticket_number = await updatedTable[0]['ticket_number'];

          updatedTable.forEach((row) {
            print(row);
          });

          print(updatedTable);

          return "200";
        } else {

          return "404";
        }
      }

    else{
      print(400);
      return "400";
    }




  }

  Future<String> search_platenum(String? platenumber) async
  {

    // To access the database itself
    final db = await database;

    List<Map> searchresult = await db.rawQuery(
        'SELECT * FROM $_issuedticketstable WHERE $_issuedticketsplatenumber = ? AND $_issuedticketsstatus = ?',
        [platenumber, ticketstatus]
    );

    if (searchresult.isNotEmpty) {
      fetchedtimein_print = await searchresult[0][_issuedticketstimein];
      ticket_number = await searchresult[0][_issuedticketsnumber];
      print(searchresult);
      print(fetchedtimein_print);

      return  "200";

    } else {
      return  "404";
    }


  }

  Future <String> update_issued_receipt(String? platenumber, String? timeout, String? hours, String? total) async
  {
    final db = await database;
    String status = "paid";

    // Actual insert query to insert data in database

    Map<String, dynamic> values = {
      _issuedticketstimeout: timeout,
      _issuedticketshours: hours,
      _issuedticketstotal: total,
      _issuedticketsstatus: status,
      _ticketapistatus: '404',
    };

    int check = await db.update(_issuedticketstable, values,
        where: '$_issuedticketsplatenumber = ? AND $_issuedticketsstatus = ?',
        whereArgs: [platenumber, 'pending']);

    if(check > 0)
      {
        return "200";
      }
    else
      {
        return "404";
      }

  }

  Future <String> insert_toilet_receipt(String? price, String time) async
  {
    final db = await database;


    int id = await db.insert(
      _toiletreceipttable,
      {
        _toiletreceiptprice: price,
        _toiletreceipttime: time,
        _toiletapistatus: '404'
      },
    );

    if (id > 0) {


      final List<Map<String, dynamic>> updatedTable = await db.query(
          _toiletreceipttable,
          where: '$_toiletreceipttime = ?',
          whereArgs: [time]
      );

     toilet_time = await time;

     print(updatedTable);

      return "200";

    } else {
      return "404";

    }

  }


  void checkdata() async
  {
    final db = await database;

    List<Map> list = await db.rawQuery('SELECT * FROM $_ticket_detailstable WHERE $_ticket_detailsid = 1');
    List<Map> list1 = await db.rawQuery('SELECT * FROM $_mobilepos_configurationtable WHERE $_mobilepos_configurationid = 1');
    List<Map<String, dynamic>> list2 = await db.query(_issuedticketstable,
      where: '$_ticketapistatus = ? AND $_issuedticketsstatus = ?',
      whereArgs: ['404', 'paid'],);

    List<Map<String, dynamic>> list3 = await db.query(_issuedticketstable);
    List<Map<String, dynamic>> list4 = await db.query(_toiletreceipttable);
    //print(list);
    //print(list1);
    print("CURRENT ISSUED TICKET DATABASE");
    print(list3);

    /*
    list2.forEach((row){
      print(row);
    });

     */



  }

  Future <String> uploaddata() async {
    final db = await database;

    // Query the database
    List<Map<String, dynamic>> upload = await db.query(
      _issuedticketstable,
      where: '$_ticketapistatus = ? ',
      whereArgs: ['404'],
    );

    print(upload);

    List<Map<String, dynamic>> upload1 = await db.query(
      _toiletreceipttable,
      where: '$_toiletapistatus = ?',
      whereArgs: ['404'],
    );

    if (upload.isEmpty && upload1.isEmpty) {
      print('No data to upload');
      return "404";
    }

    // Print the retrieved data
    //print(upload);

    // Create a new list with the required keys
    List<Map<String, dynamic>> uploads = [];
    upload.forEach((row) {
      uploads.add({
        'ticket_number': row[_issuedticketsnumber],
        'plate_number': row[_issuedticketsplatenumber],
        'time-in': row[_issuedticketstimein],
        'time-out': row[_issuedticketstimeout],
        'hours': row[_issuedticketshours],
        'total': row[_issuedticketstotal],
        'status': row[_issuedticketsstatus],
      });
    });

    List<Map<String, dynamic>> uploads1 = [];
    upload1.forEach((row) {
      uploads1.add({
        'price': row[_toiletreceiptprice],
        'time': row[_toiletreceipttime],
      });
    });

    print(uploads);
    print(uploads1);

    /*
    uploads.forEach((row) {
      print(row);
    });
     */

    try
    {
      final apilink = hostaddress + "/api/upload";

      // Send the POST request
      final response = await http.post(
        Uri.parse(apilink),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(uploads),
      );

      // Print the response
      print(response.body);

      if(response.statusCode == 200)
        {

          Map<String, dynamic> values = {
            _ticketapistatus: '200',
          };

          await db.update(_issuedticketstable, values,
              where: '$_ticketapistatus = ? ', // AND $_issuedticketsstatus = ?
              whereArgs: ['404' /*,'paid'*/]);

          final apilink1 = hostaddress + "/api/uploadtoilet";

          // Send the POST request
          final response1 = await http.post(
            Uri.parse(apilink1),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(uploads1),
          );

          if(response1.statusCode == 200)
            {


              Map<String, dynamic> values1 = {
                _toiletapistatus: '200',
              };



              await db.update(_toiletreceipttable, values1,
                  where: '$_toiletapistatus = ?',
                  whereArgs: ['404']);

              checkdata();

              return "200";
            }

          else
            {
              print(response1.body);
              return "201";
            }


        }
      else
        {
          print(response.body);

          return "422";
        }

    }
    catch(e)
    {
      print(e);
      return "422";
    }

  }

}
