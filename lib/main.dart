import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts',
      theme: ThemeData(
        primaryColor: Colors.black,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black, // Set the cursor color
          selectionColor:
              Colors.black.withOpacity(0.3), // Set the selection color
          selectionHandleColor: Colors.black, // Set the selection handle color
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.5)), // Set hint text color
          labelStyle: TextStyle(color: Colors.black), // Set label text color
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
      ),
      home: ContactList(),
    );
  }
}

class ContactList extends StatefulWidget {
  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];

  TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final file =
        File('${(await getApplicationDocumentsDirectory()).path}/contacts.vcf');

    if (file.existsSync()) {
      final jsonData = json.decode(file.readAsStringSync());

      setState(() {
        contacts = (jsonData['contacts'] as List)
            .map<Contact>((contact) => Contact.fromJson(contact))
            .toList();

        filteredContacts = List.from(contacts);
      });
    }
  }

  void _saveContacts() async {
    final file =
        File('${(await getApplicationDocumentsDirectory()).path}/contacts.vcf');
    file.writeAsStringSync(json.encode({'contacts': contacts}));
  }

  void _addContact(Contact contact) {
    if (contact.name.trim().isNotEmpty &&
        contact.phoneNumber.trim().isNotEmpty) {
      if (contact.phoneNumber.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
            content: Text("Can't save. Phone Number should be 10 digits long.",
                style: TextStyle(fontFamily: 'Product Sans', fontSize: 16)),
          ),
        );
        return;
      }
      setState(() {
        contacts.add(contact);
        filteredContacts = List.from(contacts);
      });

      _saveContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          content: Text("Can't save. Name and Phone Number are required.",
              style: TextStyle(fontFamily: 'Product Sans', fontSize: 16)),
        ),
      );
    }
  }

  void _editContact(int index, Contact contact) {
    setState(() {
      contacts[index] = contact;
    });

    setState(() {
      filteredContacts = List.from(contacts);
    });

    _saveContacts();
  }

  void _deleteContact(int index) {
    setState(() {
      contacts.removeAt(index);
    });

    setState(() {
      filteredContacts = List.from(contacts);
    });

    _saveContacts();
  }

  void _filterContacts(String query) {
    // Filter contacts based on the query
    setState(() {
      filteredContacts = contacts
          .where((contact) =>
              contact.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: _isSearching ? Colors.black12 : Colors.black,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  hintText: 'Search Contacts',
                  hintStyle: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Product Sans'),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: TextStyle(
                    color: Colors.black87,
                    fontFamily: 'Product Sans',
                    fontSize: 17),
              )
            : Text(
                'Contacts',
                style:
                    TextStyle(color: Colors.white, fontFamily: 'Product Sans'),
              ),
        titleSpacing: 25,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: _isSearching ? Colors.black : Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filterContacts('');
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          SizedBox(width: 18)
        ],
        toolbarHeight: 80,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        itemCount: filteredContacts.length,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            leading: CircleAvatar(
              backgroundImage: filteredContacts[index].image != null
                  ? MemoryImage(
                      Uint8List.fromList(filteredContacts[index].image!))
                  : null,
              backgroundColor: Colors.black12,
              radius: 30,
            ),
            title: Text(
              filteredContacts[index].name,
              style: const TextStyle(fontSize: 20, fontFamily: 'Product Sans'),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetails(
                    contact: filteredContacts[index],
                    onEdit: (contact) => _editContact(index, contact),
                    onDelete: () => _deleteContact(index),
                  ),
                ),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.call, color: Colors.black),
              onPressed: () async {
                FlutterPhoneDirectCaller.callNumber(
                    filteredContacts[index].phoneNumber);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddContact(onSubmit: _addContact),
            ),
          );
        },
        tooltip: 'Add Contact',
        label: const Text('Add Contact',
            style: TextStyle(fontFamily: 'Product Sans', color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.black,
      ),
    );
  }
}

class Contact {
  String name;
  String phoneNumber;
  List<int>? image;

  Contact({
    required this.name,
    required this.phoneNumber,
    this.image,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'image': image,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      image: json['image'] != null ? List<int>.from(json['image']) : null,
    );
  }
}

class ContactDetails extends StatelessWidget {
  final Contact contact;
  final Function(Contact) onEdit;
  final Function onDelete;

  ContactDetails({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 70,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditContact(contact: contact, onSubmit: onEdit),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text('Delete Contact',
                        style: TextStyle(
                            fontSize: 20, fontFamily: 'Product Sans')),
                    content: Text(
                        'Are you sure you want to delete this contact ??',
                        style: TextStyle(fontFamily: 'Product Sans')),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel',
                            style: TextStyle(
                                fontFamily: 'Product Sans',
                                color: Colors.black)),
                      ),
                      TextButton(
                        onPressed: () {
                          onDelete();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text('Delete',
                            style: TextStyle(
                                color: Colors.red, fontFamily: 'Product Sans')),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          SizedBox(width: 8)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (contact.image != null)
              Center(
                child: CircleAvatar(
                  backgroundImage:
                      MemoryImage(Uint8List.fromList(contact.image!)),
                  radius: 80,
                  backgroundColor: Colors.black12,
                ),
              ),
            SizedBox(height: 20),
            Text('${contact.name}',
                style: TextStyle(
                  fontSize: 28,
                  fontFamily: 'Product Sans',
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(height: 8.0),
            Text('+91 ${contact.phoneNumber}',
                style: TextStyle(fontSize: 20, fontFamily: 'Product Sans')),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                FlutterPhoneDirectCaller.callNumber(contact.phoneNumber);
              },
              child: Text('Call',
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Product Sans',
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddContact extends StatefulWidget {
  final Function(Contact) onSubmit;

  AddContact({required this.onSubmit});

  @override
  _AddContactState createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  List<int>? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _image = [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        centerTitle: true,
        title: Text('Add Contact',
            style: TextStyle(color: Colors.black, fontFamily: 'Product Sans')),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(25, 16, 25, 16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                _pickImage();
              },
              child: _image?.isNotEmpty ?? false
                  ? CircleAvatar(
                      backgroundImage: MemoryImage(Uint8List.fromList(_image!)),
                      radius: 70,
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.black26,
                      radius: 60,
                      child: Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            ),
            SizedBox(height: 20),
            TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: 'Name',
                    floatingLabelStyle: TextStyle(
                        color: Colors.black, fontFamily: 'Product Sans')),
                style: TextStyle(
                    color: Colors.black87, fontFamily: 'Product Sans')),
            SizedBox(height: 20),
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                  labelText: 'Phone Number',
                  floatingLabelStyle: TextStyle(
                      color: Colors.black, fontFamily: 'Product Sans')),
              style:
                  TextStyle(color: Colors.black87, fontFamily: 'Product Sans'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                final newContact = Contact(
                  name: _nameController.text,
                  phoneNumber: _phoneNumberController.text,
                  image: _image,
                );

                widget.onSubmit(newContact);
                Navigator.pop(context);
              },
              child: Text('Save Contact',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Product Sans',
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path).readAsBytesSync();
      });
    }
  }
}

class EditContact extends StatefulWidget {
  final Contact contact;
  final Function(Contact) onSubmit;

  EditContact({required this.contact, required this.onSubmit});

  @override
  _EditContactState createState() => _EditContactState();
}

class _EditContactState extends State<EditContact> {
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  List<int>? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneNumberController =
        TextEditingController(text: widget.contact.phoneNumber);
    _image = widget.contact.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        centerTitle: true,
        title: Text('Edit Contact',
            style: TextStyle(color: Colors.black, fontFamily: 'Product Sans')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                _pickImage();
              },
              child: _image != null && _image!.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: MemoryImage(Uint8List.fromList(_image!)),
                      radius: 60,
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.black26,
                      radius: 80,
                      child: Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                      ),
                    ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                  labelText: 'Name',
                  floatingLabelStyle: TextStyle(
                      color: Colors.black, fontFamily: 'Product Sans'),
                  hintStyle: TextStyle(
                      color: Colors.black, fontFamily: 'Product Sans')),
              style:
                  TextStyle(color: Colors.black87, fontFamily: 'Product Sans'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                  labelText: 'Phone Number',
                  floatingLabelStyle: TextStyle(
                      color: Colors.black, fontFamily: 'Product Sans')),
              style:
                  TextStyle(color: Colors.black87, fontFamily: 'Product Sans'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _submitEdit();
              },
              child: Text('Save Changes',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Product Sans',
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitEdit() {
    final name = _nameController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();

    if (name.isNotEmpty && phoneNumber.length == 10) {
      final editedContact = Contact(
        name: _nameController.text,
        phoneNumber: _phoneNumberController.text,
        image: _image,
      );

      widget.onSubmit(editedContact);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        content: Text(
            "Can't edit. Name is required and Phone Number should be 10 digits long.",
            style: TextStyle(fontFamily: 'Product Sans', fontSize: 16)),
      ));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path).readAsBytesSync();
      });
    }
  }
}
