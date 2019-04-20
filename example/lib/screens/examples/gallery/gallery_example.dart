import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view_example/screens/app_bar.dart';
import 'package:photo_view_example/screens/examples/gallery/gallery_example_item.dart';

class GalleryExample extends StatelessWidget {
  void open(BuildContext context, final int index) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GalleryPhotoViewWrapper(
                galleryItems: galleryItems,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                initialIndex: index,
              ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const ExampleAppBar(
            title: "Gallery Example",
            showGoBack: true,
          ),
          Expanded(
              child: Center(
                  child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GalleryExampleItemThumbnail(
                galleryExampleItem: galleryItems[0],
                onTap: () {
                  open(context, 0);
                },
              ),
              GalleryExampleItemThumbnail(
                galleryExampleItem: galleryItems[1],
                onTap: () {
                  open(context, 1);
                },
              ),
              GalleryExampleItemThumbnail(
                galleryExampleItem: galleryItems[2],
                onTap: () {
                  open(context, 2);
                },
              ),
            ],
          ))),
        ],
      ),
    );
  }
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  GalleryPhotoViewWrapper(
      {this.loadingChild,
      this.backgroundDecoration,
      this.minScale,
      this.maxScale,
      this.initialIndex,
      @required this.galleryItems})
      : pageController = PageController(initialPage: initialIndex);

  final Widget loadingChild;
  final Decoration backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<GalleryExampleItem> galleryItems;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  int currentIndex;
  @override
  void initState() {
    currentIndex = widget.initialIndex;
    super.initState();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: widget.backgroundDecoration,
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: <Widget>[
              PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: AssetImage(widget.galleryItems[index].image),
                    initialScale:
                        PhotoViewComputedScale.contained * (0.8 + index / 2),
                    minScale:
                        PhotoViewComputedScale.contained * (0.5 + index / 10),
                    maxScale: PhotoViewComputedScale.covered * 1.1,
                    heroTag: galleryItems[index].id,
                  );
                },
                itemCount: galleryItems.length,
                loadingChild: widget.loadingChild,
                backgroundDecoration: widget.backgroundDecoration,
                pageController: widget.pageController,
                onPageChanged: onPageChanged,
              ),
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Image ${currentIndex + 1}",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17.0, decoration: null),
                ),
              )
            ],
          )),
    );
  }
}