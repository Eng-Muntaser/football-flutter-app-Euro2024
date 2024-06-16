import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uefa/bloc/euro_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uefa/data/euro_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FixturesScreen extends StatefulWidget {
  const FixturesScreen({super.key});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  void _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    print("Connectivity Result: $connectivityResult");
    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text(
              'Please check your internet connection and try again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          elevation: 5,
          backgroundColor: Colors.white,
          title: BlocBuilder<EuroBloc, EuroState>(
            builder: (context, state) {
              if (state is LoadedEuroState) {
                final league = state.fixturesList.isNotEmpty
                    ? state.fixturesList.first.league
                    : null;
                return league != null
                    ? Column(
                        children: [
                          SizedBox(
                            height: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(30),
                            child: Image.network(
                              league.logo.toString(),
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 35,
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Text('Euro 2024',
                        style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 16));
              }
              return Text('Euro 2024',
                  style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16));
            },
          ),
          toolbarHeight: 80,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue.shade900),
              onPressed: () {
                _checkInternetConnection();
                context.read<EuroBloc>().add(LoadEuroEvent());
              },
            ),
          ],
          bottom: TabBar(
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            labelColor: Colors.blue.shade900,
            indicatorColor: Colors.blue.shade900,
            indicatorWeight: 5.0,
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Next'),
              Tab(text: 'Last'),
            ],
          ),
        ),
        body: BlocBuilder<EuroBloc, EuroState>(
          builder: (context, state) {
            if (state is LoadingEuroState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is LoadedEuroState) {
              return TabBarView(
                children: [
                  FixturesList(
                      fixturesList: state.fixturesList, filter: 'today'),
                  GroupedFixturesList(
                      fixturesList: state.fixturesList, filter: 'next'),
                  GroupedFixturesList(
                      fixturesList: state.fixturesList, filter: 'last'),
                ],
              );
            } else if (state is ErrorEuroState) {
              print(state.ErrorMsg);
              return const Center(child: Text('Error loading fixtures'));
            }

            return const Center(child: Text('Welcome'));
          },
        ),
      ),
    );
  }
}

class FixturesList extends StatelessWidget {
  final List<ResponseModel> fixturesList;
  final String filter;

  const FixturesList({required this.fixturesList, required this.filter});

  @override
  Widget build(BuildContext context) {
    List<ResponseModel> filteredFixtures = [];
    DateTime today = DateTime.now();
    DateTime todayStart = DateTime(today.year, today.month, today.day);
    DateTime todayEnd =
        DateTime(today.year, today.month, today.day, 23, 59, 59);

    if (filter == 'today') {
      filteredFixtures = fixturesList.where((fixture) {
        DateTime fixtureDate =
            DateTime.parse(fixture.fixture!.date!.toString()).toLocal();
        return fixtureDate.isAfter(todayStart) &&
            fixtureDate.isBefore(todayEnd);
      }).toList();
    }

    if (filteredFixtures.isEmpty) {
      return Center(
        child: Text(
          'No fixtures for today',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredFixtures.length,
      itemBuilder: (context, index) {
        final fixture = filteredFixtures[index];
        DateTime fixtureDateTime =
            DateTime.parse(fixture.fixture!.date!.toString()).toLocal();
        String formattedDate =
            DateFormat('EEE, MMM d, h:mm a').format(fixtureDateTime);
        String todayfixture =
            "Today " + DateFormat('h:mm a').format(fixtureDateTime);
        String DateNow = DateFormat('EEE, MMM d').format(DateTime.now());
        String formatedDateTimeTesting =
            DateFormat('EEE, MMM d').format(fixtureDateTime);

        // Check if the fixture date is tomorrow
        DateTime tomorrow = today.add(Duration(days: 1));
        String tomorrowFormatted = DateFormat('EEE, MMM d').format(tomorrow);
        bool isTomorrow = formatedDateTimeTesting == tomorrowFormatted;

        return Center(
          child: Card(
            elevation: 10,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      // League and live status
                      if (fixture.fixture!.status!.elapsed != null &&
                          fixture.fixture!.status!.short != 'FT' &&
                          fixture.fixture!.status!.short != 'AET' &&
                          fixture.fixture!.status!.short != 'PEN')
                        Row(
                          children: [
                            const Text(
                              'Live ',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              fixture.fixture!.status!.elapsed.toString(),
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 4, 121, 8)),
                            ),
                            const Text(
                              "'",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 2, 71, 4)),
                            )
                          ],
                        ),
                      const SizedBox(height: 5),
                      // Fixture date and time
                      fixture.goals!.home == null
                          ? SizedBox(
                              child: formatedDateTimeTesting == DateNow
                                  ? Text(
                                      todayfixture,
                                      style: const TextStyle(
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    )
                                  : isTomorrow
                                      ? Text(
                                          'Tomorrow ' +
                                              DateFormat('h:mm a')
                                                  .format(fixtureDateTime),
                                          style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        )
                                      : Text(
                                          formattedDate,
                                          style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 20),
                      // Team logos and names
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          logoNameTeam(
                            logo: fixture.teams!.home!.logo.toString(),
                            name: fixture.teams!.home!.name.toString(),
                          ),
                          if (fixture.goals!.home != null) ...[
                            Text(
                              fixture.goals!.home.toString(),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange),
                            ),
                            const Text(" : ",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              fixture.goals!.away.toString(),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange),
                            ),
                          ],
                          logoNameTeam(
                            logo: fixture.teams!.away!.logo.toString(),
                            name: fixture.teams!.away!.name.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget logoNameTeam({required String logo, required String name}) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(2, 3), // changes position of shadow
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.black,
            radius: 28.1,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 28,
              child: ClipOval(
                child: Image.network(
                  logo,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 40,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        SizedBox(
          width: 120,
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        )
      ],
    );
  }
}

class GroupedFixturesList extends StatefulWidget {
  final List<ResponseModel> fixturesList;
  final String filter;

  const GroupedFixturesList({required this.fixturesList, required this.filter});

  @override
  _GroupedFixturesListState createState() => _GroupedFixturesListState();
}

class _GroupedFixturesListState extends State<GroupedFixturesList> {
  final Map<String, bool> _expandedState = {};

  @override
  Widget build(BuildContext context) {
    List<ResponseModel> filteredFixtures = [];
    DateTime today = DateTime.now();
    DateTime todayStart = DateTime(today.year, today.month, today.day);
    DateTime todayEnd =
        DateTime(today.year, today.month, today.day, 23, 59, 59);

    if (widget.filter == 'next') {
      filteredFixtures = widget.fixturesList.where((fixture) {
        DateTime fixtureDate =
            DateTime.parse(fixture.fixture!.date!.toString()).toLocal();
        return fixtureDate.isAfter(todayEnd);
      }).toList();
    } else if (widget.filter == 'last') {
      filteredFixtures = widget.fixturesList.where((fixture) {
        DateTime fixtureDate =
            DateTime.parse(fixture.fixture!.date!.toString()).toLocal();
        return fixtureDate.isBefore(todayStart);
      }).toList();
    }

    // Sort the filtered fixtures by date
    filteredFixtures.sort((a, b) {
      DateTime dateA = DateTime.parse(a.fixture!.date!.toString()).toLocal();
      DateTime dateB = DateTime.parse(b.fixture!.date!.toString()).toLocal();
      return dateA.compareTo(dateB);
    });

    if (filteredFixtures.isEmpty) {
      return Center(
        child: Text(
          widget.filter == 'next' ? 'No upcoming fixtures' : 'No past fixtures',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Group fixtures by date
    Map<String, List<ResponseModel>> groupedFixtures = {};
    for (var fixture in filteredFixtures) {
      String formattedDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(fixture.fixture!.date!.toString()).toLocal());
      if (groupedFixtures.containsKey(formattedDate)) {
        groupedFixtures[formattedDate]!.add(fixture);
      } else {
        groupedFixtures[formattedDate] = [fixture];
      }
    }

    return ListView(
      children: groupedFixtures.entries.map((entry) {
        String date = entry.key;
        List<ResponseModel> fixtures = entry.value;

        // Check if the date is tomorrow
        DateTime entryDate = DateTime.parse(date);
        DateTime tomorrow = today.add(Duration(days: 1));
        bool isTomorrow = entryDate.year == tomorrow.year &&
            entryDate.month == tomorrow.month &&
            entryDate.day == tomorrow.day;

        bool isExpanded = _expandedState[date] ?? false;

        return ExpansionTile(
          title: isExpanded
              ? SizedBox.shrink()
              : Center(
                  child: Text(
                    isTomorrow
                        ? 'Tomorrow'
                        : DateFormat('EEE, MMM d').format(DateTime.parse(date)),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
          onExpansionChanged: (bool expanded) {
            setState(() {
              _expandedState[date] = expanded;
            });
          },
          children: fixtures.map((fixture) {
            DateTime fixtureDateTime =
                DateTime.parse(fixture.fixture!.date!.toString()).toLocal();
            String formattedDate =
                DateFormat('EEE, MMM d, h:mm a').format(fixtureDateTime);
            String todayfixture =
                "Today " + DateFormat('h:mm a').format(fixtureDateTime);
            String DateNow = DateFormat('EEE, MMM d').format(DateTime.now());
            String formatedDateTimeTesting =
                DateFormat('EEE, MMM d').format(fixtureDateTime);

            // Check if the fixture date is tomorrow
            String tomorrowFormatted =
                DateFormat('EEE, MMM d').format(tomorrow);
            bool isFixtureTomorrow =
                formatedDateTimeTesting == tomorrowFormatted;

            return Center(
              child: Card(
                elevation: 10,
                shadowColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          // League and live status
                          if (fixture.fixture!.status!.elapsed != null &&
                              fixture.fixture!.status!.short != 'FT' &&
                              fixture.fixture!.status!.short != 'AET' &&
                              fixture.fixture!.status!.short != 'PEN')
                            Row(
                              children: [
                                const Text(
                                  'Live ',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  fixture.fixture!.status!.elapsed.toString(),
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 1, 45, 3)),
                                ),
                                const Text(
                                  "'",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 1, 45, 3)),
                                )
                              ],
                            ),
                          const SizedBox(height: 10),
                          // Fixture date and time
                          fixture.goals!.home == null
                              ? SizedBox(
                                  child: formatedDateTimeTesting == DateNow
                                      ? Text(
                                          todayfixture,
                                          style: const TextStyle(
                                              color: Colors.deepOrange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        )
                                      : isFixtureTomorrow
                                          ? Text(
                                              'Tomorrow ' +
                                                  DateFormat('h:mm a')
                                                      .format(fixtureDateTime),
                                              style: TextStyle(
                                                  color: Colors.blue.shade900,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            )
                                          : Text(
                                              formattedDate,
                                              style: TextStyle(
                                                  color: Colors.blue.shade900,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                )
                              : const SizedBox.shrink(),
                          const SizedBox(height: 10),
                          // Team logos and names
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              logoNameTeam(
                                logo: fixture.teams!.home!.logo.toString(),
                                name: fixture.teams!.home!.name.toString(),
                              ),
                              if (fixture.goals!.home != null) ...[
                                Text(
                                  fixture.goals!.home.toString(),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange),
                                ),
                                const Text(" : ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  fixture.goals!.away.toString(),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange),
                                ),
                              ],
                              logoNameTeam(
                                logo: fixture.teams!.away!.logo.toString(),
                                name: fixture.teams!.away!.name.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget logoNameTeam({required String logo, required String name}) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(2, 3), // changes position of shadow
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.black,
            radius: 28.1,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 28,
              child: ClipOval(
                child: Image.network(
                  logo,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 40,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        SizedBox(
          width: 120,
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        )
      ],
    );
  }
}
