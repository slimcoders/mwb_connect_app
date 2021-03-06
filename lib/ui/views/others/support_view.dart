import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:mwb_connect_app/service_locator.dart';
import 'package:mwb_connect_app/utils/colors.dart';
import 'package:mwb_connect_app/core/services/authentication_service.dart';
import 'package:mwb_connect_app/core/services/local_storage_service.dart';
import 'package:mwb_connect_app/core/services/translate_service.dart';
import 'package:mwb_connect_app/core/models/support_request_model.dart';
import 'package:mwb_connect_app/core/viewmodels/support_request_view_model.dart';
import 'package:mwb_connect_app/ui/widgets/background_gradient.dart';

class SupportView extends StatefulWidget {
  SupportView({this.auth});

  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  LocalizationDelegate _localizationDelegate;
  LocalStorageService _storageService = locator<LocalStorageService>();
  TranslateService _translator = locator<TranslateService>();
  PageController _controller = PageController(viewportFraction: 1, keepPage: true);
  KeyboardVisibilityNotification _keyboardVisibility = KeyboardVisibilityNotification();
  int _keyboardVisibilitySubscriberId;
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  String _supportText;
  bool _sendButtonPressed = false;

  @protected
  void initState() {
    super.initState();
    _keyboardVisibilitySubscriberId = _keyboardVisibility.addNewListener(
      onChange: (bool visible) {
        if (visible) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _keyboardVisibility.removeListener(_keyboardVisibilitySubscriberId);
  }

  Widget _showSupport(BuildContext context) {
    return Container(
      height: double.infinity,
      child: PageView(
        controller: _controller,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          _showForm(),
          _showConfirmation()
        ],
      )
    );
  }  

  Widget _showForm() {
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          children: <Widget>[
            _showSupportTitle(),
            _showInput(),
            _showSendButton()
          ],
        )
      )
    );
  }

  Widget _showSupportTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: <Widget>[
          Text(
            _translator.getText('support.label'),
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(
              _translator.getText('support.sub_label'),
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.white
              ),
            ) 
          )
        ],
      )
    );
  }

  Widget _showInput() {
    return Container(
      height: 150.0,
      padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 0.0),
      child: Card(
        elevation: 3,
        child: TextFormField(
          maxLines: null,
          style: TextStyle(
            fontSize: 15.0
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),          
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.SILVER),
            hintText: _translator.getText('support.message_placeholder'),
          ), 
          validator: (value) {
            if (_sendButtonPressed && value.isEmpty) {
              return _translator.getText('support.message_error');
            } else {
              return null;
            }
          },
          onChanged: (value) {
            setState(() {
              _sendButtonPressed = false;
            });          
            Future.delayed(const Duration(milliseconds: 20), () {        
              if (value.isNotEmpty) {
                _formKey.currentState.validate();
              }
            });
          },             
          onSaved: (value) => _supportText = value.trim(),
        ),
      ),
    );
  }

  Widget _showSendButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 30.0),
        child: RaisedButton(
          elevation: 2.0,
          padding: const EdgeInsets.fromLTRB(40.0, 12.0, 40.0, 12.0),
          splashColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0)
          ),
          color: AppColors.MONZA,
          child: Text(
            _translator.getText('support.send_request'),
            style: TextStyle(fontSize: 16.0, color: Colors.white)
          ),
          onPressed: () async {
            setState(() {
              _sendButtonPressed = true;
            });
            _validateAndSubmit();
          }
        )
      ),
    );
  }
  
  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      try {
        // Just a delay effect for the send request
        await Future.delayed(const Duration(milliseconds: 300));
        _sendRequest(_supportText);
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  // Check if form is valid
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }
  
  Future<void> _sendRequest(String text) async {
    SupportRequestViewModel requestViewModel = locator<SupportRequestViewModel>();
    SupportRequest request = SupportRequest(
      text: text,
      userId: _storageService.userId,
      userEmail: _storageService.userEmail,
      userName: _storageService.userName,
      dateTime: DateTime.now()
    );
    requestViewModel.addSupportRequest(request);
    _goToConfirmation();
  }

 void _goToConfirmation() {
    _controller.animateToPage(_controller.page.toInt() + 1,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease
    );
  }   

  Widget _showConfirmation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25.0, 120.0, 25.0, 0.0),
      child: Text(
        _translator.getText('support.confirmation'),
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.white
        ),
      ),
    );
  }   

  Widget _showTitle() {
    return Container(
      padding: const EdgeInsets.only(right: 50.0),
      child: Center(
        child: Text(_translator.getText('support.title'),),
      )
    );
  }   

  @override
  Widget build(BuildContext context) {
    _localizationDelegate = LocalizedApp.of(context).delegate;    
    _translator.localizationDelegate = _localizationDelegate;  

    return Stack(
      children: <Widget>[
        BackgroundGradient(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: _showTitle(),
            backgroundColor: Colors.transparent,          
            elevation: 0.0,
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(null),
            )
          ),
          extendBodyBehindAppBar: true,
          body: _showSupport(context)
        )
      ],
    );
  }  
}
