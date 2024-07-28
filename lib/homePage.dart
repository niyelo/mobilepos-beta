//necessary libraries
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'services/database_service.dart';
import 'variable/status.dart';


//ui imports
import 'loginPage.dart';
import 'asset/themecolor.dart';
import 'package:mobilepos_beta/bluetoothPrint.dart';
import 'toiletbluetoothPrint.dart';

import 'variable/receiptdata.dart';
import 'variable/hostaddress.dart';

const Color appColor = Colors.deepPurple; // Define the color you want to use

class home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: appColor,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appColor,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  void _refreshPage() async{
    await fetchdata();
  }
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
  @override

  Timer? _timer;
  final DatabaseService _databaseService = DatabaseService.instance;



  void initState() {
    // TODO: implement initState


    super.initState();
    _databaseService.fetchticketandconfiguration();
    assigntoken();
    _databaseService.checkdata();


    //_timer = Timer.periodic(Duration(seconds: 1), (Timer t) => fetchdata());
  }

  Future <void> assigntoken() async
  {
    String status = await _databaseService.assigntoken();

    if(status == "200")
      {
        fetchdata();
      }
    else if(status == "404")
      {
        await _databaseService.assigntoken();
      }
  }

  Future<void> fetchdata() async {
    try {
      final apilink = await hostaddress + "/api/fetch";
      final response = await http.get(Uri.parse(await apilink),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        // Check if response body is valid JSON
        try {
          Map<String, dynamic> company_details = jsonDecode(response.body);

          //receipt details
          String temp_receipt_title = company_details['details'][0]['title'];
          String temp_toilet_title = company_details['details'][0]['toilet_title'];
          String temp_company_name = company_details['details'][0]['company_name'];
          String temp_company_address = company_details['details'][0]['company_address'];
          String temp_footer = company_details['details'][0]['footer'];
          String temp_parking_price = company_details['parking_rate'][0];
          String temp_toilet_price = company_details['toilet_rate'][0];

          List<dynamic> pending_data = company_details['pending_data'];


          String storedetails = await _databaseService.storeticketdetails(
              temp_receipt_title, temp_toilet_title, temp_company_name,
              temp_company_address, temp_footer, temp_parking_price, temp_toilet_price, pending_data);

          if (storedetails == "200") {
            print("SUCCESSFULLY INSERTED DATA FROM API TO DATABASE");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Updating Details in Api is Successful"),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
          } else if (storedetails == "404") {
            print("SOMETHING WENT WRONG WITH THE DATABASE. PLEASE TRY AGAIN");

          }
        } catch (e) {
          // Handle case where response is not JSON
          print("Failed to decode JSON: $e");
          print("Response body: ${response.body}");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Updating Details in Api Failed"),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("Error: ${response.statusCode}");
        print("Response body: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Something went wrong in Api server, please try again"),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );

      }
    } catch (e) {
      print(e);
    }
  }



  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: appColor),
          ),
          bottom: const TabBar(
            indicatorColor: appColor,
            tabs: [
              Tab(icon: Icon(FontAwesomeIcons.car, color: appColor)),
              Tab(icon: Icon(FontAwesomeIcons.toilet, color: appColor)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.upload, color: appColor,),
              onPressed: () async{
                String result = await _databaseService.uploaddata();

                if (result == "200")
                  {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Uploading data in database successfully uploaded to server"),
                        duration: Duration(seconds: 3),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                else if (result == "404")
                  {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("No data can be uploaded"),
                        duration: Duration(seconds: 3),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }

                else if (result == "201")
                {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Parking Tickets are uploaded but Toilet have problem"),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: appColor,),
              onPressed: _refreshPage,
            ),

          ],
        ),
        body: TabBarView(
          children: [
            HomeScreen(),
            ToiletScreen(), // Updated to ToiletScreen
          ],
        ),
        drawer: MainDrawer(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final TextEditingController plateController = TextEditingController();

  void _timeIn(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TimeInDialog(plateController: plateController);
      },
    );
  }

  void _timeOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TimeOutDialog(plateController: plateController);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Issue Parking Ticket',
          style: TextStyle(color: appColor),
        ),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _timeIn(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Time In', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: () => _timeOut(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Time Out', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeInDialog extends StatefulWidget {
  final TextEditingController plateController;

  TimeInDialog({required this.plateController});

  @override
  _TimeInDialogState createState() => _TimeInDialogState();
}

class _TimeInDialogState extends State<TimeInDialog> {
  late Timer _timer;
  late String _currentTime;

  final DatabaseService _databaseService = DatabaseService.instance;
  String message = "";

  @override
  void initState() {
    super.initState();
    _currentTime = _getCurrentTime();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = _getCurrentTime();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getCurrentTime() {
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  }

  Future<void> validate_platenum() async
  {
    try
    {
      final apilink = hostaddress + "/api/platevalidation";


      Map<String, dynamic> send_platenum =
      {
        "plate_number" : print_platenum
      };

      final response = await http.post(Uri.parse(apilink),body: send_platenum,  headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'});

      Map<String, dynamic> apiresponse = Map<String, dynamic>.from(jsonDecode(response.body));
      print(apiresponse['response']);
      print(apiresponse['message']);

    }
    catch(e)
    {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Time In: $_currentTime', style: TextStyle(
          color: Colors.black54, fontSize: 20
      ),),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: widget.plateController,
              decoration: InputDecoration(
                hintText: 'Enter Plate Number',
                border: OutlineInputBorder(),
              ),
            ),
        SizedBox(height: 3,),
        Text(message, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog without any action
          },
          child: Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () async{
            String plateNumber = widget.plateController.text;
            timein_print = _currentTime;
            print_platenum = plateNumber.toUpperCase();
            print(plateNumber);
            print(_currentTime);


            if(plateNumber == "" || plateNumber == " " || plateNumber.isEmpty)
              {
                setState(() {
                  message = "Input cant be blank";
                });
              }
            else
              {
                String insert = await _databaseService.insert_issued_tickets(plateNumber.toUpperCase(), timein_print!);
                if(insert == "200")
                {
                  print("SUCESSFULLY INSERT TO DATABASE");
                  validate_platenum();
                  if(mounted)
                  {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BluetoothPrintPage()));
                  }

                }
                else if(insert == "404")
                {
                  print("FAILED INSERT TO DATABASE");
                }

                else if(insert == "400")
                  {
                    setState(() {
                      message = "Plate Number have pending unpaid ticket";
                    });
                  }
              }


          },
          child: Text('Print', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class TimeOutDialog extends StatefulWidget {
  final TextEditingController plateController;

  TimeOutDialog({required this.plateController});

  @override
  _TimeOutDialogState createState() => _TimeOutDialogState();
}

class _TimeOutDialogState extends State<TimeOutDialog> {
  late Timer _timer;
  late String _currentTime;
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _currentTime = _getCurrentTime();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = _getCurrentTime();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getCurrentTime() {
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  }

  double calculateTotalValue(DateTime timeIn, DateTime timeOut, double pricePerHour) {
    Duration duration = timeOut.difference(timeIn);
    double hour = duration.inMinutes / 60.0;

    // If duration is less than or equal to 1 hour, charge for 1 hour
    if (hour <= 1.0) {
      hours = hour.toStringAsFixed(2);
      return pricePerHour;
    }

    // If duration is more than 1 hour, round up to the nearest hour
    hours = hour.toStringAsFixed(2);
    return pricePerHour * hour.ceil();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Time Out: $_currentTime', style: TextStyle(
          color: Colors.black54, fontSize: 19
      ),),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: widget.plateController,
              decoration: InputDecoration(
                hintText: 'Enter Plate Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 3,),
            Text(messages, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),)
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              messages = "";
            });
            Navigator.pop(context); // Close the dialog without any action
          },
          child: Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () async {

            String plateNumber = widget.plateController.text;

            timeout_print = _currentTime;
            print_platenum = plateNumber.toUpperCase();

            String? existing = await _databaseService.search_platenum(print_platenum);

            if (existing == "200") {

              setState(() {
                messages = "";
              });
              print("PLATE NUMBER FOUND ON DATABASE");

              DateTime timeIn = DateFormat("yyyy-MM-dd HH:mm:ss").parse(fetchedtimein_print);
              DateTime timeOut = DateFormat("yyyy-MM-dd HH:mm:ss").parse(timeout_print);

              print(fetchedtimein_print);
              print(timeout_print);
              double pricePerHour = double.parse(parking_rate);

              double totalValue = calculateTotalValue(timeIn, timeOut, pricePerHour);

              print (hours);
              print("Total Value " + totalValue.toStringAsFixed(2));

              String? update = await _databaseService.update_issued_receipt(print_platenum,timeout_print, hours, totalValue.toStringAsFixed(2));

              if (update == "200")
                {
                  print("RECEIPT UPDATED SUCCESSFULLY");

                  timein_print = fetchedtimein_print;
                  parking_price = totalValue.toStringAsFixed(2);

                  setState(() {
                    if(mounted)
                      {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => BluetoothPrintPage()));
                      }

                  });

                }

              else if (update == "404")
                {
                  print("RECEIPT UPDATED ERROR HAS OCCURED");

                }

              else
                {
                  print("UNKNOWN ERROR");

                }



            } else if (existing == "404") {
              setState(() {
                messages = "Plate Number Not Existing";
              });
              print("PLATE NUMBER NOT FOUND IN DATABASE");

            } else {
              print("ERROR SEARCHING PLATE NUMBER");

            }
          },
          child: Text('Search', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class ToiletScreen extends StatefulWidget {
  @override
  _ToiletScreenState createState() => _ToiletScreenState();
}

class _ToiletScreenState extends State<ToiletScreen> {
  late String _currentTime;
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _currentTime = _getCurrentTime();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getCurrentTime() {
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Toilet Receipt',
          style: TextStyle(color: appColor),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            bool proceed = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Print Receipt?',
                  style: TextStyle(color: Colors.black54),),
                  content: const Text('Do you want to proceed with printing the receipt?',
                    style: TextStyle(color: Colors.black54),),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Cancel',
                        style: TextStyle(color: Colors.white),),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Proceed',
                        style: TextStyle(color: Colors.white),),
                    ),
                  ],
                );
              },
            );

            if (proceed) {
              String timenow = _currentTime;
              String toilet_response = await _databaseService.insert_toilet_receipt(toilet_price, timenow);

              if (toilet_response == "200") {
                print("Toilet Data Inserted successfully");
              } else if (toilet_response == "404") {
                print("Toilet Data Inserted failed");
              } else {
                print("Unknown Error Occurred");
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => toiletBluetoothPrintPage()),
              );
            }
          },
          child: const Text(
            'ISSUE RECEIPT',
            style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}


class MainDrawer extends StatelessWidget {
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
  @override

  final DatabaseService _databaseService = DatabaseService.instance;

  Future <String> logout() async
  {
    try{
      final apilink = hostaddress + "/api/logout";
      final response = await http.get(Uri.parse(apilink),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          });

      if(response.statusCode == 200)
      {
        Map<String, dynamic> result = jsonDecode(response.body);
        _databaseService.deletetoken();
        return "200";
      }
      else
      {
        print("Error: ${response.statusCode}");
        print("Response body: ${response.body}");
        return "404";
      }

    }
    catch(e)
    {
      print(e);
      return "404";
    }
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [appColor, appColor]),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(FontAwesomeIcons.arrowLeft, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 30),
                const Text(
                  " ",
                  style: TextStyle(fontSize: 35, color: Colors.black),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              FontAwesomeIcons.house,
              color: appColor,
              size: 20,
            ),
            title: const Text("Home"),
            onTap: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => MainPage()));
            },
          ),
          ListTile(
            leading: const Icon(
              FontAwesomeIcons.signOut,
              color: appColor,
              size: 20,
            ),
            title: const Text("Logout"),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Please Wait...'),
                    content: Text('Do you really want to Logout?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, color: appColor),),
                      ),
                      TextButton(
                        onPressed: () async {
                          String run = await logout();
                          if(run == "200")
                            {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp()));
                            }
                        },
                        child: Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, color: appColor),),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

