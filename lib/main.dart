import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Ticket Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: QRViewExample(),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  _QRViewExampleState createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? ticketContent;
  Map<String, dynamic>? responseData;
  String? errorMessage;
  var isCameraActive = true;
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      setState(() {
        isCameraActive = false;
        ticketContent = scanData.code;
      });
      _verifyTicket(ticketContent!);
    });
  }

  Future<void> _verifyTicket(String ticketContent) async {
    final url = Uri.parse(
      'https://becrez-25-backend.onrender.com/ticket/verify-ticket',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ticket_content': ticketContent}),
    );

    if (response.statusCode == 200) {
      setState(() {
        responseData = jsonDecode(response.body);
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = jsonDecode(response.body)['verbose_msg'];
        responseData = null;
      });
    }
  }

  Future<void> _markAsGiven(String ticketContent) async {
    final url = Uri.parse('https://becrez-25-backend.onrender.com/ticket/mark-as-given');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ticket_content': ticketContent}),
    );

    if (!mounted) return; // Check if the widget is still mounted
    

    setState(() {
      isCameraActive = true;
    });
    if (response.statusCode == 200) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID given successfully!')),
      );

      // Reset the app to its original state
      setState(() {
        this.ticketContent = null;
        this.responseData = null;
        this.errorMessage = null;
      });
    } else {
      // Show error message
      final errorResponse = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${errorResponse['verbose_msg']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Ticket Scanner')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: isCameraActive? QRView(key: qrKey, onQRViewCreated: _onQRViewCreated):IconButton(onPressed: (){
              _markAsGiven(ticketContent??'');
            }, icon: Text('Next')),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child:
                  ticketContent == null
                      ? const Text('Scan a QR code')
                      : responseData != null
                      ? _buildResponseWidget(responseData!)
                      : errorMessage != null
                      ? Text(
                        'Error: $errorMessage',
                        style: const TextStyle(color: Colors.red),
                      )
                      : const CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseWidget(Map<String, dynamic> responseData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Success: ${responseData['success_msg']}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text('For: ${responseData['for']}', style: TextStyle(fontSize: 16)),
          if (responseData['for'] == 'competition')
            _buildCompetitionData(responseData['data'])
          else if (responseData['for'] == 'pass')
            _buildPassData(responseData['data'])
          else if (responseData['for'] == 'techtalks') // Add this condition
            _buildTechTalksData(responseData['data']),

          //TextButton(onPressed: (){}, child: Text('Next'))
        ],
      ),
    );
  }

  Widget _buildCompetitionData(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(color: Color(data['teams']['id_card_given']?0xfff94449:0xff6fc267)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Competition Name: ${data['name']}'),
          Text('URL Code: ${data['url_code']}'),
          Text('Participants Limit: ${data['participants_limit']}'),
          Text('Team Name: ${data['teams']['team_name']}'),
          Text(
            'Created At: ${DateTime.fromMillisecondsSinceEpoch(data['teams']['created_at'])}',
          ),
          Text('ID Card Given: ${data['teams']['id_card_given']}'),
          Text('Members:'),
          for (var member in data['teams']['members'])
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${member['name']}'),
                  Text('Email: ${member['email']}'),
                  Text('Contact No: ${member['contact_no']}'),
                  Text('DOB: ${member['dob']}'),
                  Text('University: ${member['university']}'),
                  Text('Domain of Study: ${member['domain_of_study']}'),
                  Text('Degree: ${member['degree']}'),
                  Text('Branch of Study: ${member['branch_of_study']}'),
                  Text('Year of Passing: ${member['year_of_passing']}'),
                  SizedBox(height: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPassData(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(color: Color(data['id_card_given']?0xfff94449:0xff6fc267)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: ${data['name']}'),
          Text('Email: ${data['email']}'),
          Text('Contact No: ${data['contact_no']}'),
          Text('Age: ${data['age']}'),
          Text('Organization: ${data['organization']}'),
          Text('Designation: ${data['designation']}'),
          Text('ID Card Given: ${data['id_card_given']}'),
          Text(
            'Created At: ${DateTime.fromMillisecondsSinceEpoch(data['created_at'])}',
          ),
        ],
      ),
    );
  }
}

Widget _buildTechTalksData(Map<String, dynamic> data) {
  return Container(
    decoration: BoxDecoration(color: Color(data['id_card_given']?0xfff94449:0xff6fc267)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name: ${data['name']}'),
        Text('Email: ${data['email']}'),
        Text('RRN: ${data['rrn']}'),
        Text('Contact No: ${data['contact_no']}'),
        Text('DOB: ${data['dob']}'),
        Text('University: ${data['university']}'),
        Text('Domain of Study: ${data['domain_of_study']}'),
        Text('Degree: ${data['degree']}'),
        Text('Branch of Study: ${data['branch_of_study']}'),
        Text('Year of Passing: ${data['year_of_passing']}'),
        Text('ID Card Given: ${data['id_card_given']}'),
        Text(
          'Created At: ${DateTime.fromMillisecondsSinceEpoch(data['created_at'])}',
        ),
      ],
    ),
  );
}
