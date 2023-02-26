import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
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
                    children: [Text('전체'), Text('사용가능'), Text('사용불가')])
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
                              onTap : () {print('hi');}, //Todo : 상세페이지
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gifts[i]['name'],style: TextStyle(fontSize: 20)),
                                  Text(gifts[i]['place']),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat(format).format(DateTime(int.parse(gifts[i]['year']), int.parse(gifts[i]['month']), int.parse(gifts[i]['day'])))),
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
          //Todo : Image 여부에 따라서 처리하기
          print(image.runtimeType);
          if (image != null) {
            //Todo : 서버로 보내서 JSON 받아오기
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
              print('요청받은거임');
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
              //throw Exception('실패함');
              print('실패함수고');
              print(response.statusCode);
            }

          }
          else {
            print('올바르지 못한 이미지');
            return;
            //Todo : 이미지 선택 오류
          }
          //Todo : 서버로 보낸거 요청 status code 보고 예외처리


        },
        icon: Icon(Icons.add),
        label: Text('새 상품권 추가하기'),

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
          title: Text('설정'),
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          centerTitle: false,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Setting 화면')],
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
          title: Text('새 상품권 등록하기'),
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          centerTitle: false,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          //Todo : 텍스트 필드 입력받아서 result 수정(각 항목 null check)
          //Todo : 취소나 확인 시 Navigator.pop
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
                          label: '제품명',
                          onSaved: (val) {
                            setState(() {
                              name = val;
                            });
                          },
                          validator: (val) {
                            if(val.length < 1) {
                              return '제품명을 입력해주세요.';
                            }
                            return null;
                          },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['place'],
                        label: '사용처',
                        onSaved: (val) {
                          setState(() {
                            place = val;
                          });
                        },
                        validator: (val) {
                          if(val.length < 1) {
                            return '사용처를 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['year'],
                        label: '유효기간-년',
                        onSaved: (val) {
                          setState(() {
                            year = val;
                          });
                        },
                        validator: (val) {
                          if(val.length != 4) {
                            return '네 자리 숫자로 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['month'],
                        label: '유효기간-월',
                        onSaved: (val) {
                          setState(() {
                            month = val;
                          });
                        },
                        validator: (val) {
                          if(val.length < 1 || val.length > 2) {
                            return '유효기간-월을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['day'],
                        label: '유효기간-일',
                        onSaved: (val) {
                          setState(() {
                            day = val;
                          });
                        },
                        validator: (val) {
                          if(val.length < 1 || val.length > 2) {
                            return '유효기간-일을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      renderTextFormField(
                        initialValue: widget.newGift['code'],
                        label: '바코드 번호',
                        onSaved: (val) {
                          setState(() {
                            code = val;
                          });
                        },
                        validator: (val) {
                          if(int.tryParse(val) == null) {
                            return '숫자만 입력해주세요.';
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
                                child: Text('저장하기'),
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
  var text = '사용 가능';
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: (){
          widget.applyUse(widget.i);
          if(widget.isUsed == true) {
            setState(() {
              text = '사용 완료';
              back = Colors.grey;
            });
          }
          else{
            setState(() {
              text = '사용 가능';
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
  //Todo : gifts, i 추가
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
                    child: Text('선택한 상품권을 삭제하시겠습니까?', style: TextStyle(fontSize: 17),)
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
                      child: Text('목록에서만 사라지며 실제 상품권에 영향은 없습니다.', style: TextStyle(fontSize: 10)))
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
                          child: Text('취소')
                      ),
                      TextButton(
                          onPressed: (){
                            widget.deleteGift(widget.i);
                            widget.saveGifts();
                            print("done");
                            Navigator.pop(context);
                      },
                          child: Text('확인'))
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
