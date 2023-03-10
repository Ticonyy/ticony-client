import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;



void main() {
  runApp(
      MaterialApp(
          theme : ThemeData(
            fontFamily: 'NEXONLv2',
          ),
          home: MyApp()
      )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {
  final viewSelected = <bool>[true, false, false];
  var gifts = [];
  var format = 'yyyy-MM-dd';
  var storage;
  addNewGift(Map newGift) {
    setState(() {
      gifts.add(newGift);
    });
  }

  applyUse(int i) {
    setState(() {
      gifts[i]['isUsed'] = !gifts[i]['isUsed'];
    });
  }

  deleteGift(int i) {
    setState(() {
      gifts.removeAt(i);
    });
  }

  saveGifts() async {
    storage = await SharedPreferences.getInstance();
    for(int i = 0; i < gifts.length; i++) {
      gifts[i]['image'] = gifts[i]['image'].toString();
      gifts[i]['image'] = gifts[i]['image'].substring(7, gifts[i]['image'].length - 1);
    }
    storage.setString('gifts', jsonEncode(gifts));
    for(int i = 0; i < gifts.length; i++) {
      gifts[i]['image'] = File(gifts[i]['image']);
    }

  }

  loadGifts() async {
    storage = await SharedPreferences.getInstance();
    var result = storage.getString('gifts');
    print(gifts.runtimeType);
    setState(() {
      List datalist = jsonDecode(result);
      gifts = datalist;
      for(int i = 0; i < gifts.length; i++) {
        gifts[i]['image'] = File(gifts[i]['image']);
      }
    });
  }
  @override
  void initState() {
    super.initState();
    loadGifts();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticony'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: false,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
              },
              icon: Icon(Icons.settings))
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 40,
            color: Colors.white10,
            child: Row(
              children: [
                ToggleButtons(
                    color: Colors.black.withOpacity(0.60),
                    selectedColor: Colors.black,
                    fillColor: Colors.amber,
                    onPressed: (index) {
                      setState(() {
                        viewSelected[index] = !viewSelected[index];
                      });
                    },
                    isSelected: viewSelected,
                    children: [Text('??????'), Text('????????????'), Text('????????????')])
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: gifts.length,
                itemBuilder: (c, i) {
                  return Container(
                      height: 150,
                      color: Colors.white,
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Padding(
                              padding : EdgeInsets.fromLTRB(0, 0, 30, 0),
                              child: SizedBox(
                                  width: 100,
                                  height: 150,
                                  child: Image.file(gifts[i]['image'])
                              )
                          ),
                          Expanded(
                            child: InkWell(
                              onTap : () {print('hi');}, //Todo : ???????????????
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gifts[i]['name'],style: TextStyle(fontSize: 20)),
                                  Text(gifts[i]['place']),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(gifts[i]['years']+'-'+gifts[i]['month']+'-'+gifts[i]['day']),
                                      //Text(DateFormat(format).format(DateTime(int.parse(gifts[i]['year']), int.parse(gifts[i]['month']), int.parse(gifts[i]['day'])))),
                                      UseButton(applyUse : applyUse, i : i, isUsed : gifts[i]['isUsed'], saveGifts: saveGifts,),
                                      IconButton(
                                          onPressed: (){
                                            showDialog(
                                                context: context,
                                                builder: (context){
                                                  return DeleteUI(i : i, deleteGift : deleteGift, saveGifts : saveGifts);
                                                });
                                          },
                                          icon: Icon(Icons.delete_forever_outlined)
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ));
                }),
          ),
          Container(height: 50,)

        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        splashColor: Colors.amberAccent,
        onPressed: () async{
          var picker = ImagePicker();
          var image = await picker.pickImage(source: ImageSource.gallery);
          var imagePath;
          //Todo : Image ????????? ????????? ????????????
          print(image.runtimeType);
          if (image != null) {
            //Todo : ????????? ????????? JSON ????????????
            setState(() {
              imagePath = File(image.path);
            });
            List<int> imageBytes = imagePath.readAsBytesSync();
            String base64Image = base64Encode(imageBytes);
            // print(base64Image);
            Uri url = Uri.parse('https://ticony.kro.kr/file_upload');
            var response = await http.post(
              url,
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8'
              },
              body: jsonEncode([
                {'image': base64Image}
              ]),
            );
            
            // FutureBuilder(
            //   future: response,
            //   builder: (context, snapshot) {
            //     if(snapshot.hasData) {
            //       return Text('hi');
            //     }
            //     else {
            //       return CircularProgressIndicator();
            //     }
            //   }
            // );


            if(response.statusCode == 200) {
              print('??????????????????');
              print(response.body);
              var data = jsonDecode(response.body);
              print(data);
              var newGift = {'code' : data['code'].toString() ,'name' : data['name'].toString(), 'year' : data['year'].toString(), 'month' : data['month'].toString(), 'day' : data['day'].toString(), 'place' : data['place'].toString(), 'isUsed' : false, 'image':imagePath};
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewGift(addNewGift : addNewGift, newGift : newGift, saveGifts : saveGifts)),
              );
            }
            else {
              //throw Exception('?????????');
              print('???????????????');
              print(response.statusCode);
            }

          }
          else {
            print('???????????? ?????? ?????????');
            return;
            //Todo : ????????? ?????? ??????
          }
          //Todo : ????????? ????????? ?????? status code ?????? ????????????


        },
        icon: Icon(Icons.add),
        label: Text('??? ????????? ????????????'),

      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('??????'),
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          centerTitle: false,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Setting ??????')],
        )
    );
  }
}

class NewGift extends StatefulWidget {
  NewGift({Key? key, this.addNewGift, this.newGift, this.saveGifts}) : super(key: key);
  final addNewGift;
  var newGift;
  final saveGifts;
  @override
  State<NewGift> createState() => _NewGiftState();
}

class _NewGiftState extends State<NewGift> {
  String name = '';
  String year = '';
  String month = '';
  String day = '';
  String place = '';
  String code = '';

  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('??? ????????? ????????????'),
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          centerTitle: false,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          //Todo : ????????? ?????? ??????????????? result ??????(??? ?????? null check)
          //Todo : ????????? ?????? ??? Navigator.pop
          children: [
            Expanded(
              child: ListView(
                children: [Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Image.file(
                          widget.newGift['image'],
                          height: 450,
                      ),
                      renderTextFormField(
                          initialValue: widget.newGift['name'],
                          label: '?????????',
                          onSaved: (val) {
                            setState(() {
                              name = val;
                            });
                          },
                          validator: (val) {
                            if(val.length < 1) {
                              return '???????????? ??????????????????.';
                            }
                            return null;
                          },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['place'],
                        label: '?????????',
                        onSaved: (val) {
                          setState(() {
                            place = val;
                          });
                        },
                        validator: (val) {
                          if(val.length < 1) {
                            return '???????????? ??????????????????.';
                          }
                          return null;
                        },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['year'],
                        label: '????????????-???',
                        onSaved: (val) {
                          setState(() {
                            year = val;
                          });
                        },
                        validator: (val) {
                          if(val.length != 4) {
                            return '??? ?????? ????????? ??????????????????.';
                          }
                          return null;
                        },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['month'],
                        label: '????????????-???',
                        onSaved: (val) {
                          setState(() {
                            month = val;
                          });
                        },
                        validator: (val) {
                          if(val.length < 1 || val.length > 2) {
                            return '????????????-?????? ??????????????????.';
                          }
                          return null;
                        },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['day'],
                        label: '????????????-???',
                        onSaved: (val) {
                          setState(() {
                            day = val;
                          });
                        },
                        validator: (val) {
                          if(val.length < 1 || val.length > 2) {
                            return '????????????-?????? ??????????????????.';
                          }
                          return null;
                        },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['code'],
                        label: '????????? ??????',
                        onSaved: (val) {
                          setState(() {
                            code = val;
                          });
                        },
                        validator: (val) {
                          if(int.tryParse(val) == null) {
                            return '????????? ??????????????????.';
                          }
                          return null;
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: ElevatedButton(
                                onPressed: () async {
                                  if(formKey.currentState?.validate() == true) {
                                    formKey.currentState?.save();
                                    Map result = widget.newGift;
                                    result['name'] = name;
                                    result['place'] = place;
                                    result['year'] = year;
                                    result['month'] = month;
                                    result['day'] = day;
                                    result['code'] = code;
                                    widget.addNewGift(result);
                                    //Todo : saveGifts
                                    widget.saveGifts();
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black
                                ),
                                child: Text('????????????'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ),]
              ),
            ),
          ],
        )
    );
  }
}

renderTextFormField({
  required String label,
  required FormFieldSetter onSaved,
  required FormFieldValidator validator,
  required String initialValue
}) {

  return Column(
    children: [
      Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      TextFormField(
        initialValue: initialValue,
        onSaved: onSaved,
        validator: validator,
        autovalidateMode: AutovalidateMode.always,
      ),
      Container(height: 16,)
    ],
  );
}


class UseButton extends StatefulWidget {
  UseButton({Key? key, this.applyUse, this.i, this.isUsed, this.saveGifts}) : super(key: key);
  final applyUse;
  final saveGifts;
  var isUsed;
  var i;

  @override
  State<UseButton> createState() => _UseButtonState();
}

class _UseButtonState extends State<UseButton> {
  var back = Colors.amber;
  var text = '?????? ??????';
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: (){
          widget.applyUse(widget.i);
          if(widget.isUsed == true) {
            setState(() {
              text = '?????? ??????';
              back = Colors.grey;
            });
          }
          else{
            setState(() {
              text = '?????? ??????';
              back = Colors.amber;
            });
          }
          widget.saveGifts();
          print(widget.isUsed);
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: back,
            foregroundColor: Colors.black
        ),
        child: Text(text)
    );
  }
}

class DeleteUI extends StatefulWidget {
  const DeleteUI({Key? key, this.i, this.deleteGift, this.saveGifts}) : super(key: key);
  //Todo : gifts, i ??????
  final i;
  final deleteGift;
  final saveGifts;
  @override
  State<DeleteUI> createState() => _DeleteUIState();
}

class _DeleteUIState extends State<DeleteUI> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 300,
        height: 150,
        child: Column(
          children: [
            Flexible(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(10),
                height: double.infinity,
                width: double.infinity,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('????????? ???????????? ?????????????????????????', style: TextStyle(fontSize: 17),)
                )
              )
            ),
            Flexible(
                flex: 3,

                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  child: Align(
                      alignment: Alignment.topLeft,
                      child: Text('??????????????? ???????????? ?????? ???????????? ????????? ????????????.', style: TextStyle(fontSize: 10)))
                )
            ),
            Flexible(
                flex: 2,
                child: SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: (){
                            Navigator.pop(context);
                      },
                          child: Text('??????')
                      ),
                      TextButton(
                          onPressed: (){
                            widget.deleteGift(widget.i);
                            widget.saveGifts();
                            print("done");
                            Navigator.pop(context);
                      },
                          child: Text('??????'))
                    ],
                  )
                )
            )
          ],
        )
      )
    );
  }
}
