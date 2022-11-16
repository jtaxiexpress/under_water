import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image/image.dart' as uiImage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:under_water/animation.dart';
import 'package:underwater_image_color_correction/underwater_image_color_correction.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'admob.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await loadAd();
  runApp(const MyApp());
}

AppOpenAd? openAd;
//Admob Open Adsを起動
Future<void> loadAd() async {
  String adUnitId = Platform.isAndroid
      ? 'ca-app-pub-8319377204356997/8331566022'
      : 'ca-app-pub-8319377204356997/9644647690';
  await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(onAdLoaded: ((ad) {
        print('ad is loaded');
        openAd = ad;
        openAd!.show();
      }), onAdFailedToLoad: (error) {
        print('ad failed to load $error');
      }),
      orientation: AppOpenAd.orientationPortrait);
}

void showAd() {
  if (openAd == null) {
    print('tring to show before loading');
    loadAd();
    return;
  }
  openAd!.fullScreenContentCallback = FullScreenContentCallback(
    onAdShowedFullScreenContent: (ad) {
      print('onAdShowedFullScreenContent');
    },
    onAdFailedToShowFullScreenContent: (ad, error) {
      ad.dispose();
      print('faild to load $error');
      openAd = null;
      loadAd();
    },
    onAdDismissedFullScreenContent: (ad) {
      ad.dispose();
      print('dismissed');
      openAd = null;
      loadAd();
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Color correction'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BannerAd? _banner;

  final globalKey = GlobalKey();
  Uint8List? bytes;

  ImagePicker picker = ImagePicker();
  XFile? _image;

  final UnderwaterImageColorCorrection _underwaterImageColorCorrection =
      UnderwaterImageColorCorrection();
  ColorFilter? colorFilter;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _createBannerAd();
  }

  void _createBannerAd() {
    _banner = BannerAd(
        size: AdSize.fullBanner,
        adUnitId: AdMobService.bannerAdUnitId!,
        listener: AdMobService.bannerAdListener,
        request: const AdRequest())
      ..load();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).viewPadding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              height: 150,
              padding: EdgeInsets.only(top: height),
              child: Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: [
                  WaveBackground(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.photo,
                            color: Colors.white,
                            size: 30,
                          )),
                      SizedBox(
                        width: 20,
                      ),
                      IconButton(
                          onPressed: _clearData,
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 30,
                          )),
                      SizedBox(
                        width: 15,
                      ),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            //バナー広告
            Container(
                child: _banner == null
                    ? Container()
                    : Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 52,
                        child: AdWidget(ad: _banner!))),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: _image == null
                    ? const Text('')
                    : Image.file(
                        File(_image!.path),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            colorFilter == null
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: RepaintBoundary(
                      key: globalKey,
                      child: ColorFiltered(
                        colorFilter: colorFilter!,
                        child: Image.file(
                          File(_image!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _image != null ? _applyColorCorrection : null,
                    child: _image != null
                        ? const Text("Convert")
                        : IconButton(
                            onPressed: _pickImage,
                            icon: Icon(
                              Icons.photo,
                              color: Colors.grey,
                            )),
                  ),
            colorFilter != null
                ? ElevatedButton(
                    onPressed: () async {
                      await widgetToImage();
                      setState(() {});
                    },
                    child: Text('Save'))
                : Container(),
          ],
        ),
      ),
    );
  }

  void _clearData() {
    setState(() {
      colorFilter = null;
      _image = null;
    });
  }

  void _pickImage() async {
    _clearData();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  void _applyColorCorrection() async {
    setState(() {
      loading = true;
    });
    final image = uiImage.decodeImage(File(_image!.path).readAsBytesSync());
    var pixels = image!.getBytes(format: uiImage.Format.rgba);

    ColorFilter colorFilterImage =
        _underwaterImageColorCorrection.getColorFilterMatrix(
      pixels: pixels,
      width: image.width.toDouble(),
      height: image.height.toDouble(),
    );

    setState(() {
      colorFilter = colorFilterImage;
      loading = false;
    });
  }

  // 画像の保存
  Future<void> saveImage() async {
    if (_image != null) {
      Uint8List _buffer = await _image!.readAsBytes();
      final result = await ImageGallerySaver.saveImage(_buffer);
    }
  }

  Future<void> widgetToImage() async {
    final snackBar = SnackBar(
      content: Text('Success!'),
    );

    final boundary =
        globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }
    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    bytes = byteData?.buffer.asUint8List();
    final result = await ImageGallerySaver.saveImage(bytes!);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
