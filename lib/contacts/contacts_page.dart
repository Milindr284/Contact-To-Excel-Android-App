// @dart = 2.9
import 'package:contacts_app/contacts/add_contacts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../functions/functions.dart';
import 'package:csv/csv.dart';
import 'package:ext_storage/ext_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

List<String> Name = [];
List<String> ContactNumber = [];
var contactFile;
bool storagePermission;
bool contactsPermission;
String namesIndex = '1';
String contactIndex = '2';
int _counter = 0;

class contactsPage extends StatefulWidget {
  @override
  _contactsPageState createState() => _contactsPageState();
}

class _contactsPageState extends State<contactsPage> {
  List<dynamic> row = List.empty(growable: true);
  List<List<dynamic>> employeeData;
  List<Contact>listContacts;
  List<dynamic> contacts = [];
  TextEditingController namecontroller = TextEditingController();
  TextEditingController contactController = TextEditingController();

  @override
  void initState() {
    listContacts=new List();
    employeeData  = List<List<dynamic>>.empty(growable: true);
    super.initState();
    checkPermisson();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Contacts'),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/upload.svg',
                width: 200,
              ),
              SizedBox(
                width: 60,
              ),
              Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Enter The Column Number For Names'),
                    SizedBox(
                      width: 30,
                      child: TextField(
                        controller: namecontroller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          print(value);
                          namesIndex = value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
              ),
              Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Enter The Column Number For Numbers'),
                    SizedBox(
                      width: 30,
                      child: TextField(
                        controller: contactController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          print(value);
                          contactIndex = value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
              ),
              // ignore: deprecated_member_use
              RaisedButton(
                child: Text('Upload xlsx File'),
                onPressed: () async {
                  print(int.parse(namesIndex) - 1);
                  print(int.parse(contactIndex) - 1);
                  Name.clear();
                  ContactNumber.clear();
                  checkPermisson();
                  await getFile();
                  convertfileToExcel();

                  if (Name.isNotEmpty && ContactNumber.isNotEmpty) {
                    namecontroller.clear();
                    contactController.clear();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              addContacts(name: Name, number: ContactNumber)),
                    );
                  }
                },
              ),
              RaisedButton(
                  //color: Colors.blue,
                  child: Text('Export to CSV'),
                  //padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                  onPressed: () async {
                    final PermissionStatus permissionStatus = await _getPermission();
                    if (permissionStatus == PermissionStatus.granted) {
                      final contacts = Contacts.listContacts();
                      final total = await contacts.length;
                      if (await Permission.storage
                          .request()
                          .isGranted) {
                        List<dynamic> row = [];
                        row.add("Name");
                        row.add("Contact1");
                        row.add("Contact2");
                        row.add("Contact3");
                        employeeData.add(row);
                        await Contacts.streamContacts().forEach((contact) {
                          List<dynamic> row = List.empty(growable: true);
                          row.add("${contact.displayName}");
                          contact.phones.forEach((item) {
                            row.add(item.value);
                            employeeData.add(row);
                          });
                        });

//store file in documents folder

                        String dir = (await ExtStorage.getExternalStoragePublicDirectory(
                            ExtStorage.DIRECTORY_DOWNLOADS)) + "/contacts.csv";
                        String file = "$dir";

                        File f = new File(file);

// convert rows to String and write as csv file

                        String csv = const ListToCsvConverter().convert(employeeData);
                        f.writeAsString(csv);
                      } else {
                        Map<Permission, PermissionStatus> statuses = await [
                          Permission.storage,
                        ].request();
                      }
                    }
                  }),
              RaisedButton(
                child: Text('Export to Excel'),
                onPressed: () async {
                  final PermissionStatus permissionStatus = await _getPermission();
                  if (permissionStatus == PermissionStatus.granted) {
                    if (await Permission.storage
                        .request()
                        .isGranted) {
                      var excel = Excel.createExcel();
                      Sheet sheetObject = excel['Sheet1'];
                      List<String> data = ["Name","Contact"];
                      sheetObject.appendRow(data);
                      await Contacts.streamContacts().forEach((contact) {
                        List<dynamic> row = List.empty(growable: true);
                        String a = "${contact.displayName}";
                        contact.phones.forEach((item) {
                          List<String> data = [a,item.value];
                          sheetObject.appendRow(data);
                        });
                      });
                      //request for storage permission
                      var res = await Permission.storage.request();

                      //"/storage/emulated/0/Download/"  download folder address
                      //excel2.xlsx is the file name "feel free to change the file name to anything you want"

                      File file = File(("/storage/emulated/0/Download/excel2.xlsx"));
                      if (res.isGranted) {

                        if (await file.exists()) {
                          print("File exist");
                          await file.delete().catchError((e) {
                            print(e);
                          });
                        }
                        excel.encode().then((onValue) {
                          file
                            ..createSync(recursive: true)
                            ..writeAsBytesSync(onValue);
                        });
                      }
                    } else {
                      Map<Permission, PermissionStatus> statuses = await [
                        Permission.storage,
                      ].request();
                    }

                  }
                }
              ),
              RaisedButton(
                  child: Text('Export to PDF'),
                  onPressed: ()async {
                    PdfDocument document = PdfDocument();
//Create a PdfGrid class
                    PdfGrid grid = PdfGrid();
//Add the columns to the grid
                    grid.columns.add(count: 2);
//Add header to the grid
                    grid.headers.add(1);
//Add the rows to the grid
                    PdfGridRow header = grid.headers[0];
                    header.cells[0].value = 'Name';
                    header.cells[1].value = 'Contact1';
                    PdfGridRow row = grid.rows.add();

                    await Contacts.streamContacts().forEach((contact) {

                      row.cells[0].value = "${contact.displayName}";
                      contact.phones.forEach((item) {
                        row.cells[1].value = item.value;
                        row = grid.rows.add();
                      });
                    });
//Draw the grid
                    grid.draw(
                        page: document.pages.add(), bounds: Rect.zero);
//Save the document.

//Dispose the document.

                    final output = await ExtStorage.getExternalStoragePublicDirectory(
                        ExtStorage.DIRECTORY_DOWNLOADS);
                    final file = File("${output}/example.pdf");
                    await file.writeAsBytes(await document.save());
                    document.dispose();
                  }  ),
              SizedBox(
                width: 60,
              ),
              Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                    'Read Me - Before Uploading the Xlsx file.Check Column number for names and Contact number. By default, it is set to 1 & 2. If Nothing Happened, then your columns are empty.'),
              ),
            ],
          ),
        ),
      ]),
    );
  }
  Future<PermissionStatus> _getPermission() async {
    final PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
      await [Permission.contacts].request();
      return permissionStatus[Permission.contacts] ??
          PermissionStatus.restricted;
    } else {
      return permission;
    }
  }
}
