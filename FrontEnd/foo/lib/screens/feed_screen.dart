import 'dart:convert';
import 'dart:ui';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:foo/colour_palette.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/models.dart';
import 'package:foo/screens/post_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_cred.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import 'models/post_model.dart' as pst;

import 'package:foo/stories/story_builder.dart';
import 'package:foo/stories/video_trimmer/trimmer.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  // ScrollController _scrollController = ScrollController();
  // ScrollController _nestedScrollController = ScrollController();
  ScrollController _scrollController = ScrollController();
  SharedPreferences prefs;
  String curUser;
  int itemCount = 0;
  bool isConnected = false;
  GlobalKey<SliverAnimatedListState> listKey;
  bool hasRequested = false;
  double currentPos = 0;
  UserStoryModel myStory;
  List<Post> postsList = <Post>[];
  var myStoryList = [];
  AnimationController _animationController;
  AnimationController _tileAnimationController;
  //

  bool isStacked = false;
  //
  @override
  initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _tileAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    listKey = GlobalKey<SliverAnimatedListState>();

    //_fetchStory();
    super.initState();
    setInitialData();
    // _getNewPosts();

    _scrollController
      ..addListener(() {
        if (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <=
            800) {
          print("max max max");
          if (!hasRequested) {
            getPreviousPosts();
          }
          //
        }
      });
  }

  getPreviousPosts() async {
    hasRequested = true;
    print(postsList);
    var response = await http.get(Uri.http(
        localhost,
        '/api/$curUser/get_previous_posts',
        {'id': postsList.last.postId.toString()}));
    var respJson = jsonDecode(utf8.decode(response.bodyBytes));

    respJson.forEach((e) {
      Post post = Post(
          username: e['user']['username'],
          postUrl: 'http://' + localhost + e['file'],
          userDpUrl: 'assets/images/user0.png',
          postId: e['id'],
          userId: e['user']['id'],
          commentCount: e['comment_count'],
          caption: e['caption'],
          likeCount: e['likeCount'],
          haveLiked: e['hasLiked'],
          type: e['post_type']);
      int index = postsList.length - 1;
      listKey.currentState.insertItem(index);
      postsList.add(post);
      setState(() {
        itemCount += 1;
        // postsList = postsList;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _tileAnimationController.dispose();
    // _nestedScrollController.dispose();
  }

  Future<void> _checkConnectionStatus() async {
    bool result = await DataConnectionChecker().hasConnection;

    if (result == true) {
      if (mounted) {
        setState(() {
          isConnected = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isConnected = false;
        });
      }
    }
  }

  Future<void> setInitialData() async {
    prefs = await SharedPreferences.getInstance();
    curUser = prefs.getString("username");
    var feedBox = Hive.box("Feed");
    Feed feed;
    if (feedBox.containsKey("feed") && feedBox.get("feed").posts != null) {
      feed = feedBox.get("feed");

      for (int i = feed.posts.length - 1; i >= 0; i--) {
        listKey.currentState
            .insertItem(0, duration: Duration(milliseconds: 100));
        postsList.insert(0, feed.posts[i]);
      }
      setState(() {
        itemCount += postsList.length;
      });
    } else {
      feed = Feed();

      await feedBox.put('feed', feed);
    }
    await _checkConnectionStatus();
    if (isConnected) {
      var response = await http.get(Uri.http(localhost, '/api/$curUser/posts'));
      var respJson = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        respJson.reversed.toList().forEach((e) {
          Post post = Post(
              username: e['user']['username'],
              postUrl: 'http://' + localhost + e['file'],
              userDpUrl: 'assets/images/user0.png',
              postId: e['id'],
              commentCount: e['comment_count'],
              caption: e['caption'],
              userId: e['user']['id'],
              likeCount: e['likeCount'],
              haveLiked: e['hasLiked'],
              type: e['post_type']);
          feed.addPost(post);
          feed.save();
          if (feed.isNew(e['id'])) {
            listKey.currentState.insertItem(0);
            postsList.insert(0, post);
            //feed.addPost(post);

            setState(() {
              itemCount += 1;
            });
          }
        });
      }
    }
  }

  // Future<void> _fetchStory() async {
  //   await _checkConnectionStatus();
  //   var response = await http.get(Uri.http(localhost, '/api/get_stories'));
  //   setState(() {
  //     myStoryList = jsonDecode(response.body);
  //     myItemCounter = myStoryList.length + 1;
  //   });
  //   // print(myStoryList);
  // }

  //int myItemCounter = 1;

  //The widget to display the stories which fetches data using the websocket

  Widget _newHoriz() {
    return ValueListenableBuilder(
        valueListenable: Hive.box('MyStories').listenable(),
        builder: (context, box, widget) {
          // List<UserStoryModel> seenStoryList = <UserStoryModel>[];
          // List<UserStoryModel> unSeenStoryList = <UserStoryModel>[];

          var boxList = box.values.toList();
          var seenList = [];
          var unSeenList = [];
          var myStoryList = [];
          //_getCurrentStoryViewer();

          if (curUser != null) {
            for (int item = 0; item < boxList.length; item++) {
              if (boxList[item].username == curUser) {
                myStory = boxList[item];
              } else {
                if (boxList[item].hasUnSeen() == -1) {
                  seenList.add(boxList[item]);
                } else {
                  unSeenList.add(boxList[item]);
                }
              }
            }
          }
          // myStoryList = boxList.where((x) => x.username != curUser).toList();
          seenList
              .sort((a, b) => b.timeOfLastStory.compareTo(a.timeOfLastStory));
          unSeenList
              .sort((a, b) => b.timeOfLastStory.compareTo(a.timeOfLastStory));
          myStoryList = [...unSeenList, ...seenList];

          return Container(
            width: double.infinity,
            height: 120.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              //itemCount: pst.stories.length + 1,
              itemCount: myStoryList.length + 1, //myStoryList.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Column(
                    children: [
                      StoryUploadPick(myStory: myStory),
                      Text(
                        "Momentos",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                }
                return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => StoryBuilder(
                                  myStoryList: myStoryList,
                                  initialPage: index - 1,
                                  profilePic: pst.stories,
                                )),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: myStoryList[index - 1].hasUnSeen() != -1
                                  ? [
                                      Color.fromRGBO(250, 87, 142, 1),
                                      Color.fromRGBO(202, 136, 18, 1),
                                      Color.fromRGBO(253, 167, 142, 1),
                                    ]
                                  : [
                                      Color.fromRGBO(255, 255, 255, 1),
                                      Color.fromRGBO(190, 190, 190, 1),
                                    ],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(2),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(23),
                                      image: DecorationImage(
                                        image:
                                            AssetImage(pst.stories[index - 1]),
                                        // image: NetworkImage(
                                        //     'https://img.republicworld.com/republic-prod/stories/promolarge/xxhdpi/32qfhrhvfuzpdiev_1597135847.jpeg?tr=w-758,h-433'),
                                        fit: BoxFit.cover,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          myStoryList[index - 1].username,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ));
              },
            ),
          );
        });
  }

  //

  // Container _horiz() {
  //   return Container(
  //     width: double.infinity,
  //     height: 100.0,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       //itemCount: pst.stories.length + 1,
  //       itemCount: myItemCounter, //myStoryList.length + 1,
  //       itemBuilder: (BuildContext context, int index) {
  //         if (index == 0) {
  //           return StoryUploadPick();
  //         }
  //         return GestureDetector(
  //             onTap: () {
  //               print(
  //                   "You tickled ${myStoryList[index - 1]['username']} $index times");
  //               print("${myStoryList[index - 1]['stories'][0]['file']}");
  //               print("$myStoryList");
  //               print("${myStoryList.length}");
  //               Navigator.of(context).push(
  //                 MaterialPageRoute(
  //                     builder: (context) => StoryBuilder(
  //                           myStoryList: myStoryList,
  //                           initialPage: index - 1,
  //                           profilePic: pst.stories,
  //                         )),
  //               );
  //             },
  //             child: Container(
  //               margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
  //               height: 50,
  //               width: 80,
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(30),
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight,
  //                   colors: [
  //                     Color.fromRGBO(250, 87, 142, 1),
  //                     Color.fromRGBO(202, 136, 18, 1),
  //                     Color.fromRGBO(253, 167, 142, 1),
  //                   ],
  //                 ),
  //               ),
  //               child: Padding(
  //                 padding: EdgeInsets.all(3),
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(26),
  //                   ),
  //                   child: Padding(
  //                     padding: EdgeInsets.all(2),
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                           color: Colors.black,
  //                           borderRadius: BorderRadius.circular(23),
  //                           image: DecorationImage(
  //                             image: AssetImage(pst.stories[index - 1]),
  //                             // image: NetworkImage(
  //                             //     'https://img.republicworld.com/republic-prod/stories/promolarge/xxhdpi/32qfhrhvfuzpdiev_1597135847.jpeg?tr=w-758,h-433'),
  //                             fit: BoxFit.cover,
  //                           )),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             )
  //             // child: Container(
  //             //   margin: EdgeInsets.all(10.0),
  //             //   // width: 80.0,
  //             //   // height: 45.0,
  //             //   decoration: BoxDecoration(
  //             //       borderRadius: BorderRadius.circular(35),
  //             //       gradient: LinearGradient(
  //             //           begin: Alignment.topLeft,
  //             //           end: Alignment.bottomRight,
  //             //           colors: [
  //             //             Color.fromRGBO(250, 87, 142, 1),
  //             //             Palette.lightSalmon,
  //             //           ])
  //             //       // boxShadow: [
  //             //       //   BoxShadow(
  //             //       //     color: Colors.black45.withOpacity(.2),
  //             //       //     offset: Offset(0, 2),
  //             //       //     spreadRadius: 1,
  //             //       //     blurRadius: 6.0,
  //             //       //   ),
  //             //       // ],
  //             //       ),
  //             //   child: Padding(
  //             //     padding: const EdgeInsets.all(2.0),
  //             //     child: Container(
  //             //       decoration: BoxDecoration(
  //             //         color: Colors.white,
  //             //         borderRadius: BorderRadius.circular(30),
  //             //       ),
  //             //       child: Padding(
  //             //         padding: EdgeInsets.all(1),
  //             //         child: Container(
  //             //           width: 70,
  //             //           height: 40,
  //             //           decoration: BoxDecoration(
  //             //               borderRadius: BorderRadius.circular(30),
  //             //               // shape: BoxShape.circle,
  //             //               image: DecorationImage(
  //             //                 //image: AssetImage(pst.stories[index - 1]),
  //             //                 image: NetworkImage(
  //             //                     'https://img.republicworld.com/republic-prod/stories/promolarge/xxhdpi/32qfhrhvfuzpdiev_1597135847.jpeg?tr=w-758,h-433'),
  //             //                 fit: BoxFit.cover,
  //             //               )),
  //             //         ),
  //             //       ),
  //             //     ),
  //             //   ),
  //             // ),
  //             );
  //       },
  //     ),
  //   );
  // }

  Future<void> _getNewPosts() async {
    var response = await http.get(Uri.http(localhost, '/api/$curUser/posts'));
    var respJson = jsonDecode(utf8.decode(response.bodyBytes));

    var feedBox = Hive.box("Feed");
    var feed;
    if (feedBox.containsKey("feed")) {
      feed = feedBox.get('feed');
    } else {
      feed = Feed();
      await feedBox.put("feed", feed);
    }

    respJson.reversed.toList().forEach((e) {
      Post post = Post(
          username: e['user']['username'],
          postUrl: 'http://' + localhost + e['file'],
          userDpUrl: 'assets/images/user0.png',
          postId: e['id'],
          userId: e['user']['id'],
          commentCount: e['comment_count'],
          caption: e['caption'],
          likeCount: e['likeCount'],
          haveLiked: e['hasLiked'],
          type: e['post_type']);
      feed.addPost(post);
      feed.save();
      if (feed.isNew(e['id'])) {
        listKey.currentState.insertItem(0);
        postsList.insert(0, post);

        setState(() {
          itemCount += 1;
          // postsList = postsList;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = math.min(540.0, MediaQuery.of(context).size.height * .7);
    var heightFactor = (height - 58) / height;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(double.infinity, 60),
          child: Container(
            width: double.infinity,
            height: 60,
            color: Colors.white,
          ),
        ),
        // extendBodyBehindAppBar: true,
        // extendBody: true,
        // backgroundColor: Color.fromRGBO(24, 4, 29, 1),
        // backgroundColor: Color.fromRGBO(218, 228, 237, 1),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
        floatingActionButton: TextButton(
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  var feedBox = Hive.box("Feed");
                  Feed feed = feedBox.get("feed");
                  listKey.currentState.insertItem(0);
                  postsList.insert(0, feed.posts[0]);
                },
                child: Text(
                  "hoi",
                  style: TextStyle(color: Colors.black, fontSize: 30),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (isStacked) {
                    _tileAnimationController
                        .reverse()
                        .whenComplete(() => setState(() {
                              isStacked = false;
                            }));
                  } else {
                    _tileAnimationController
                        .forward()
                        .whenComplete(() => setState(() {
                              isStacked = true;
                            }));
                  }
                },
                child: Text(
                  "anm",
                  style: TextStyle(color: Colors.black, fontSize: 30),
                ),
              ),
            ],
          ),
          onPressed: () {},
        ),
        backgroundColor: Colors.white,
        body: Container(
          // margin: EdgeInsets.only(bottom: 40),
          // padding: const EdgeInsets.only(bottom: 40),
          child: RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: () {
              _getNewPosts();
              //_fetchStory();
              return Future.value('nothing');
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                //SliverToBoxAdapter(child: _horiz()),
                SliverToBoxAdapter(child: _newHoriz()),
                SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverAnimatedList(
                  initialItemCount: itemCount,
                  key: listKey,
                  // controller: _scrollController,
                  itemBuilder: (context, index, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                              begin: Offset(0, -.4), end: Offset(0, 0))
                          .animate(CurvedAnimation(
                              parent: animation, curve: Curves.easeInOut)),
                      child: FadeTransition(
                        opacity:
                            Tween<double>(begin: 0, end: 1).animate(animation),
                        child: AnimatedBuilder(
                            animation: _tileAnimationController,
                            builder: (context, child) {
                              var val = _tileAnimationController.value;
                              var value = .08 * val;
                              return Align(
                                heightFactor: 1 - value,
                                alignment: Alignment.topCenter,
                                child: PostTile(
                                    post: postsList[index],
                                    index: index,
                                    isLast: index == (postsList.length - 1)
                                        ? true
                                        : false),
                              );
                            }),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
