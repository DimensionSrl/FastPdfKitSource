appledoc \
-h \
-d \
-u \
--docset-publisher-name "MobFarm" \
--docset-bundle-name FastPdfKit \
--docset-bundle-id com.mobfarm.fastpdfkit \
--docset-publisher-id "com.mobfarm" \
--keep-intermediate-files \
-o ~/git/FastPdfKitCore/Docs \
-t ~/git/appledoc/Templates \
-p FastPdfKit -c "MobFarm" \
--company-id com.mobfarm \
--docset-feed-url "http://doc.fastpdfkit.com/docset.atom" \
--docset-package-url "http://doc.fastpdfkit.com/docset.xar" \
--docset-atom-filename "docset.atom" \
--docset-package-filename "docset.xar" \
-v "3.1.3" \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFPDFOutlineEntry.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFOverlayTouchable.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFOverlayDrawable.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFDocumentViewController.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFDocumentViewControllerDelegate.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFDocumentManager.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/Stuff.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFDocumentOverlayDataSource.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFTextItem.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFAudioProvider.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/MFAudioPlayerViewProtocol.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/FPKOverlayViewDataSource.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/FPKAnnotation.h \
~/git/FastPdfKitCore/FastPdfKitLibrary/FPKURIAnnotation.h
echo "Copying Documentation to the Xserve"
scp -r ~/git/FastPdfKitCore/Docs/html/* mobfarm.eu:/Library/WebServer/docs/FastPdfKit/
echo "Publishing Docset"
scp -r ~/git/FastPdfKitCore/Docs/publish/* mobfarm.eu:/Library/WebServer/docs/FastPdfKit/