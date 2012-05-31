# This is a simple script that compiles the plugin using MXMLC (free & cross-platform).
# To use, make sure you have downloaded and installed the Flex SDK in the following directory:
FLEXPATH=/Developer/SDKs/flex_sdk_3

echo "Compiling with MXMLC..."
$FLEXPATH/bin/mxmlc ../src/com/livestation/plugins/googleanalytics/GoogleAnalytics.as -sp ../src -o ../googleanalytics.swf -library-path+=../lib -load-externs=../lib/sdk-classes.xml -use-network=false -optimize=true -incremental=false
cp ../googleanalytics.swf /Users/joeconnor/git/api-livestation-com/public/player/5.7/plugins/googleanalytics.swf