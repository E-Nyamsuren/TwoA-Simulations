#region Header

/*
Copyright 2015 Enkhbold Nyamsuren (http://www.bcogs.net , http://www.bcogs.info/)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Namespace: TestApp
Filename: Program_OneTwoThree.cs
*/

#endregion Header

namespace TestApp 
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using System.Reflection;
    using System.IO;

    using TwoA;
    using AssetPackage;
    using TileZero;

    partial class Program 
    {
        public const string resourceNS = "TestApp.Resources.";

        public const string contentPath = @"Resources\";
        public const string OneTwoThreeSimResultsPath = @"OneTwoThreeSimResults\";

        public static Random rnd = new Random();

        public static void doOneTwoThreeSimControl() {
            string adaptID = "Game difficulty - Player skill";
            string gameID = "OneTwoThree";

            // [SC] create Bridge instance
            MyBridge bridge = new MyBridge();

            // [SC] instantiate the TwoA asset
            TwoA twoA = new TwoA(bridge);

            // [SC] a lis of player in order of gameplays in datafile
            List<DataRecord> dataRecordList = new List<DataRecord>();

            // [SC] contains info about scenarios such as level and mirror group
            Dictionary<string, ScenarioData> scenarioDatabase = new Dictionary<string, ScenarioData>();

            // [SC] load the data file
            Dictionary<int, PlayerData> playerDatabase = parseOneTwoThreeDatafile(twoA, adaptID, gameID, dataRecordList, scenarioDatabase);
            if (playerDatabase == null) {
                return;
            }

            foreach (DataRecord dataRecord in dataRecordList) {
                twoA.UpdateRatings(adaptID, gameID, "" + dataRecord.PlayerID, dataRecord.ScenarioID, dataRecord.RT, dataRecord.Accuracy, false);
            }

            // [SC] creating a file with final ratings
            using (StreamWriter ratingfile = new StreamWriter(Path.Combine(OneTwoThreeSimResultsPath, "ratings_control.txt"))) {
                string line = ""
                    + "\"ScenarioID\""
                    + "\t" + "\"Rating\""
                    + "\t" + "\"PlayCount\""
                    + "\t" + "\"Uncertainty\""
                    + "\t" + "\"MirrorID\""
                    + "\t" + "\"SetLevel\"";

                ratingfile.WriteLine(line);

                foreach (ScenarioData scenarioData in scenarioDatabase.Values) {
                    line = ""
                        + "\"" + scenarioData.ScenarioID + "\""
                        + "\t" + "\"" + twoA.ScenarioRating(adaptID, gameID, scenarioData.ScenarioID) + "\""
                        + "\t" + "\"" + twoA.ScenarioPlayCount(adaptID, gameID, scenarioData.ScenarioID) + "\""
                        + "\t" + "\"" + twoA.ScenarioUncertainty(adaptID, gameID, scenarioData.ScenarioID) + "\""
                        + "\t" + "\"" + scenarioData.MirrorID + "\""
                        + "\t" + "\"" + scenarioData.SetLevel + "\"";

                    ratingfile.WriteLine(line);
                }
            }

            // [SC] creating a file with history of gameplays including player and scenario ratings
            using (StreamWriter datafile = new StreamWriter(Path.Combine(OneTwoThreeSimResultsPath, "gameplay_control.txt"))) {
                GameplaysData gameplays = twoA.GameplaysData;
                TwoAAdaptation adaptNode = gameplays.Adaptation.First(p => p.AdaptationID.Equals(adaptID));
                TwoAGame gameNode = adaptNode.Game.First(p => p.GameID.Equals(gameID));

                string line = ""
                    + "ID"
                    + "\t" + "PlayerID"
                    + "\t" + "ScenarioID"
                    //+ "\t" + "Timestamp"
                    + "\t" + "RT"
                    + "\t" + "ccuracy"
                    + "\t" + "PlayerRating"
                    + "\t" + "ScenarioRating";

                datafile.WriteLine(line);

                int id = 1;
                foreach (TwoAGameplay gp in gameNode.Gameplay) {
                    /*line = ""
                        + "\"" + id++ + "\""
                        + "\t" + "\"" + gp.PlayerID + "\""
                        + "\t" + "\"" + gp.ScenarioID + "\""
                        + "\t" + "\"" + gp.Timestamp + "\""
                        + "\t" + "\"" + gp.RT + "\""
                        + "\t" + "\"" + gp.Accuracy + "\""
                        + "\t" + "\"" + gp.PlayerRating + "\""
                        + "\t" + "\"" + gp.ScenarioRating + "\"";*/

                    line = ""
                        + id++
                        + "\t" + gp.PlayerID
                        + "\t" + gp.ScenarioID
                        + "\t" + gp.RT
                        + "\t" + gp.Accuracy
                        + "\t" + Math.Round(gp.PlayerRating, 5)
                        + "\t" + Math.Round(gp.ScenarioRating, 5);

                    datafile.WriteLine(line);
                }
            }
        }

        public static void doOneTwoThreeSim() {
            string adaptID = "Game difficulty - Player skill";
            string gameID = "OneTwoThree";

            // [SC] create Bridge instance
            MyBridge bridge = new MyBridge();

            // [SC] instantiate the TwoA asset
            TwoA twoA = new TwoA(bridge);
            double distMean = 0.75;
            double distSD = 0.1;
            double lowerLimit = 0.5;
            double upperLimit = 1.0;
            twoA.SetTargetDistribution(distMean, distSD, lowerLimit, upperLimit);

            // [SC] a lis of player in order of gameplays in datafile
            List<DataRecord> dataRecordList = new List<DataRecord>();

            // [SC] contains info about scenarios such as level and mirror group
            Dictionary<string, ScenarioData> scenarioDatabase = new Dictionary<string, ScenarioData>(); 

            // [SC] load the data file
            Dictionary<int, PlayerData> playerDatabase = parseOneTwoThreeDatafile(twoA, adaptID, gameID, dataRecordList, scenarioDatabase);
            if (playerDatabase == null) {
                return;
            }

            int blockSize = 20;
            foreach(string mode in new string[] { "old", "new" }) {
                for (int blockIndex = 0; blockIndex < blockSize; blockIndex++) {

                    int lastCounted = 0;
                    int counter = 0;
                    int counterInterval = 10000;

                    // [SC] approach 1
                    /*foreach (DataRecord dataRecord in dataRecordList) {
                        int playerID = dataRecord.PlayerID;

                        // [SC] decide which scenario this player should play
                        string scenarioID = twoA.TargetScenarioIDOld(adaptID, gameID, "" + playerID, true);

                        // [SC] obtain response time and accuracy
                        PlayerData playerData = playerDatabase[playerID];
                        ScenarioData scenarioData = playerData.GetScenario(scenarioID);
                        if (scenarioData == null) { // [SC] the player has not played the scenario
                            // [SC] use another scenario of similar set level
                            int setLevel = scenarioDatabase[scenarioID].SetLevel;
                            scenarioData = playerData.GetScenario(setLevel); // [TODO] possible error point
                        }
                        if (scenarioData == null) {
                            ScenarioData scenarioDataOverall = scenarioDatabase[scenarioID];
                            twoA.UpdateRatings(adaptID, gameID, "" + playerID, scenarioID
                                , scenarioDataOverall.GetAvgRT(), scenarioDataOverall.GetAvgAccuracy(), false);
                        }
                        else {
                            ScenarioRecord scenarioRecord = scenarioData.GetRecord();
                            twoA.UpdateRatings(adaptID, gameID, "" + playerID, scenarioID, scenarioRecord.RT, scenarioRecord.Accuracy, false);
                        }

                        if (++counter - lastCounted == counterInterval) {
                            lastCounted = counter;
                            printMsg("" + counter);
                        }
                    }*/

                    // [SC] approach 2
                    foreach (DataRecord dataRecord in dataRecordList) {
                        int playerID = dataRecord.PlayerID;

                        // [SC] decide which scenario this player should play
                        string scenarioID;
                        if (mode.Equals("old")) {
                            scenarioID = twoA.TargetScenarioIDOld(adaptID, gameID, "" + playerID, true);
                        }
                        else {
                            scenarioID = twoA.TargetScenarioID(adaptID, gameID, "" + playerID);
                        }

                        // [SC] obtain response time and accuracy
                        PlayerData playerData = playerDatabase[playerID];
                        ScenarioData scenarioData = playerData.GetScenario(scenarioID);
                        ScenarioRecord scenarioRecord;
                        if (scenarioData == null) { // [SC] the player has not played the scenario
                            // [SC] use a random record from all players of the scenario
                            ScenarioData scenarioDataOverall = scenarioDatabase[scenarioID];
                            scenarioRecord = scenarioDataOverall.GetRandomRecord();
                        }
                        else {
                            scenarioRecord = scenarioData.GetRecord();
                        }

                        twoA.UpdateRatings(adaptID, gameID, "" + playerID, scenarioID, scenarioRecord.RT, scenarioRecord.Accuracy, false);

                        if (++counter - lastCounted == counterInterval) {
                            lastCounted = counter;
                            printMsg("" + counter);
                        }
                    }

                    // [SC] approach 3
                    /*foreach (DataRecord dataRecord in dataRecordList) {
                        //int playerID = dataRecord.PlayerID;
                        int playerID = dataRecordList[0].PlayerID;

                        // [SC] decide which scenario this player should play
                        string scenarioID;
                        if (mode.Equals("old")) {
                            scenarioID = twoA.TargetScenarioIDOld(adaptID, gameID, "" + playerID, true);
                        }
                        else {
                            scenarioID = twoA.TargetScenarioID(adaptID, gameID, "" + playerID);
                        }

                        ScenarioData scenarioDataOverall = scenarioDatabase[scenarioID];
                        ScenarioRecord scenarioRecord = scenarioDataOverall.GetRandomRecord();
                        twoA.UpdateRatings(adaptID, gameID, "" + playerID, scenarioID, scenarioRecord.RT, scenarioRecord.Accuracy, false);

                        if (++counter - lastCounted == counterInterval) {
                            lastCounted = counter;
                            printMsg("" + counter);
                        }
                    }*/

                    // [SC] creating a file with final ratings
                    using (StreamWriter ratingfile = new StreamWriter(Path.Combine(OneTwoThreeSimResultsPath, "ratings_" + mode + "_" + blockIndex + ".txt"))) {
                        string line = ""
                            + "\"ScenarioID\""
                            + "\t" + "\"Rating\""
                            + "\t" + "\"PlayCount\""
                            + "\t" + "\"Uncertainty\""
                            + "\t" + "\"MirrorID\""
                            + "\t" + "\"SetLevel\"";

                        ratingfile.WriteLine(line);

                        foreach (ScenarioData scenarioData in scenarioDatabase.Values) {
                            ScenarioNode scenarioNode = twoA.Scenario(adaptID, gameID, scenarioData.ScenarioID);

                            line = ""
                                + "\"" + scenarioData.ScenarioID + "\""
                                + "\t" + "\"" + scenarioNode.Rating + "\""
                                + "\t" + "\"" + scenarioNode.PlayCount + "\""
                                + "\t" + "\"" + scenarioNode.Uncertainty + "\""
                                + "\t" + "\"" + scenarioData.MirrorID + "\""
                                + "\t" + "\"" + scenarioData.SetLevel + "\"";

                            ratingfile.WriteLine(line);

                            // [SC] reseting scenario data
                            scenarioNode.Rating = 0.001;
                            scenarioNode.PlayCount = 0;
                            scenarioNode.KFactor = 0.0075;
                            scenarioNode.Uncertainty = 1.0;
                            scenarioNode.LastPlayed = "2012-12-31T11:59:59";
                        }
                    }

                    // [SC] creating a file with history of gameplays including player and scenario ratings
                    using (StreamWriter datafile = new StreamWriter(Path.Combine(OneTwoThreeSimResultsPath, "gameplay_" + mode + "_" + blockIndex + ".txt"))) {
                        GameplaysData gameplays = twoA.GameplaysData;
                        TwoAAdaptation adaptNode = gameplays.Adaptation.First(p => p.AdaptationID.Equals(adaptID));
                        TwoAGame gameNode = adaptNode.Game.First(p => p.GameID.Equals(gameID));

                        string line = ""
                            + "ID"
                            + "\t" + "PlayerID"
                            + "\t" + "ScenarioID"
                            //+ "\t" + "Timestamp"
                            + "\t" + "RT"
                            + "\t" + "Accuracy"
                            + "\t" + "PlayerRating"
                            + "\t" + "ScenarioRating";

                        datafile.WriteLine(line);

                        int id = 1;
                        foreach (TwoAGameplay gp in gameNode.Gameplay) {
                            /*line = ""
                                + "\"" + id++ + "\""
                                + "\t" + "\"" + gp.PlayerID + "\""
                                + "\t" + "\"" + gp.ScenarioID + "\""
                                + "\t" + "\"" + gp.Timestamp + "\""
                                + "\t" + "\"" + gp.RT + "\""
                                + "\t" + "\"" + gp.Accuracy + "\""
                                + "\t" + "\"" + gp.PlayerRating + "\""
                                + "\t" + "\"" + gp.ScenarioRating + "\"";*/

                            line = ""
                                + id++
                                + "\t" + gp.PlayerID
                                + "\t" + gp.ScenarioID
                                + "\t" + gp.RT
                                + "\t" + gp.Accuracy
                                + "\t" + Math.Round(gp.PlayerRating, 5)
                                + "\t" + Math.Round(gp.ScenarioRating, 5);

                            datafile.WriteLine(line);
                        }

                        // [SC] clearing all gameplay
                        gameNode.Gameplay.Clear();
                    }

                    // [SC] resetting player data
                    List<PlayerNode> playerNodeList = twoA.AdaptationData.AdaptationList.First(p => p.AdaptationID.Equals(adaptID)).GameList.First(p => p.GameID.Equals(gameID)).PlayerData.PlayerList;
                    foreach (PlayerNode playerNode in playerNodeList) {
                        playerNode.Rating = 0.001;
                        playerNode.PlayCount = 0;
                        playerNode.KFactor = 0.0075;
                        playerNode.Uncertainty = 1.0;
                        playerNode.LastPlayed = "2012-12-31T11:59:59";
                    }
                }
            }
        }

        private static Dictionary<int, PlayerData> parseOneTwoThreeDatafile(TwoA twoA, string adaptId, string gameId, List<DataRecord> dataRecordList, Dictionary<string, ScenarioData> scenarioDatabase) {
            using (StreamReader reader = new StreamReader(Path.Combine(contentPath, "user_data.txt"))) {
                string line = null;
                bool headerFlag = true;

                char[] separators = new char[] { '\t' };

                Dictionary<int, PlayerData> playerDatabase = new Dictionary<int, PlayerData>();

                int lastCounted = 0;
                int counter = 0;
                int counterInterval = 100000;

                while ((line = reader.ReadLine()) != null) {
                    if (headerFlag) {
                        // [SC] skip header
                        headerFlag = false;
                        continue;
                        //TrialID	UserID	MirrorID	ItemID	SetLevel	C1	C2	C3	RT	Correct
                    }

                    string[] cols = line.Split(separators);

                    string mirrorId = cols[2];
                    string scenarioId = cols[3];
                    int trialId, playerId, setLevel, accuracy, rt;
                    if (!(Int32.TryParse(cols[0], out trialId)
                        && Int32.TryParse(cols[1], out playerId)
                        && Int32.TryParse(cols[4], out setLevel)
                        && Int32.TryParse(cols[9], out accuracy)
                        && Int32.TryParse(cols[8], out rt)
                        )) {
                        // [SC] parsing error
                        return null;
                    }

                    dataRecordList.Add(new DataRecord { 
                        TrialID = trialId,
                        PlayerID = playerId,
                        MirrorID = mirrorId,
                        ScenarioID = scenarioId,
                        SetLevel = setLevel,
                        RT = rt,
                        Accuracy = accuracy
                    });

                    PlayerData playerData;
                    if (!playerDatabase.TryGetValue(playerId, out playerData)) {
                        playerData = new PlayerData(playerId);
                        playerDatabase.Add(playerId, playerData);
                        twoA.AddPlayer(adaptId, gameId, "" + playerId);
                    }

                    ScenarioData scenarioData = playerData.AddScenario(mirrorId, scenarioId, setLevel);
                    scenarioData.AddRecord(trialId, accuracy, rt);
                    twoA.AddScenario(adaptId, gameId, scenarioId);

                    if (!scenarioDatabase.ContainsKey(scenarioId)) {
                        scenarioDatabase.Add(scenarioId, new ScenarioData(mirrorId, scenarioId, setLevel));
                    }
                    ScenarioData scenarioDataPooled = scenarioDatabase[scenarioId];
                    scenarioDataPooled.AddRecord(trialId, accuracy, rt);

                    if (++counter - lastCounted == counterInterval) {
                        lastCounted = counter;
                        printMsg("" + counter);
                    }
                }

                // [SC] for test purpose only
                /*printMsg(String.Format("Number of trials in the ordered list: {0}", playerOrderedList.Count));

                GameNode gameNode = twoA.AdaptationData.AdaptationList.First(p => p.AdaptationID.Equals(adaptId)).GameList.First(p => p.GameID.Equals(gameId));
                printMsg(String.Format("Player count in list and dictionary: {0}, {1} "
                    , gameNode.PlayerData.PlayerList.Count, gameNode.PlayerData.playerDict.Count));
                printMsg(String.Format("Scenario count in list and in dictionary: {0}, {1}"
                    , gameNode.ScenarioData.ScenarioList.Count, gameNode.ScenarioData.scenarioDict.Count));*/

                // [SC] for test purpose only
                /*foreach (KeyValuePair<int, PlayerData> playerDataPair in playerDatabase) {
                    PlayerData playerData = playerDataPair.Value;
                    printMsg(String.Format("Player key: {0}, {1}", playerDataPair.Key, playerData.PlayerID));

                    foreach (KeyValuePair<string, ScenarioData> scenarioDataPair in playerData.scenarioDatabase) {
                        ScenarioData scenarioData = scenarioDataPair.Value;
                        printMsg(String.Format("\tScenario key: {0}, {1}", scenarioDataPair.Key, scenarioData.ScenarioID));
                        printMsg(String.Format("\tScenario mirror ID: {0}, SetLevel: {1}", scenarioData.MirrorID, scenarioData.SetLevel));

                        foreach (ScenarioRecord record in scenarioData.scenarioRecords) {
                            printMsg(String.Format("\t\tTrialID: {0}, RT: {1}, Accuracy: {2}, Used: {3}", record.TrialID, record.RT, record.Accuracy, record.Used));
                        }
                    }
                }*/

                // [SC] for test purpose only
                /*int trialCounter = 0;
                foreach (KeyValuePair<int, PlayerData> playerDataPair in playerDatabase) {
                    PlayerData playerData = playerDataPair.Value;

                    foreach (KeyValuePair<string, ScenarioData> scenarioDataPair in playerData.scenarioDatabase) {
                        ScenarioData scenarioData = scenarioDataPair.Value;

                        trialCounter += scenarioData.scenarioRecords.Count;
                    }
                }
                if (1383964 != trialCounter) {
                    printMsg("Invalid number of trial records.");
                } else {
                    printMsg("All trial records parsed");
                }*/

                printMsg("================= Data file parsed.");

                return playerDatabase;
            }
        }
    }

    class DataRecord 
    {
        public int TrialID {
            get;
            set;
        }

        public int PlayerID {
            get;
            set;
        }

        public string MirrorID {
            get;
            set;
        }

        public string ScenarioID {
            get;
            set;
        }

        public int SetLevel {
            get;
            set;
        }

        public int RT {
            get;
            set;
        }

        public int Accuracy {
            get;
            set;
        }
    }

    class ScenarioRecord 
    {
        public int TrialID {
            get;
            private set;
        }

        public int Accuracy {
            get;
            private set;
        }

        public double RT {
            get;
            private set;
        }

        public ScenarioRecord(int trialId, int accuracy, double rt) {
            this.TrialID = trialId;
            this.Accuracy = accuracy;
            this.RT = rt;
        }
    }

    class ScenarioData 
    {
        private int usedIndex = -1;

        // [TODO] access modifier to private
        private List<ScenarioRecord> scenarioRecords = new List<ScenarioRecord>();
        private Dictionary<int, ScenarioRecord> scenarioDict = new Dictionary<int, ScenarioRecord>();

        public string MirrorID {
            get;
            private set;
        }

        public string ScenarioID { 
            get;
            private set; 
        }

        public int SetLevel {
            get;
            private set;
        }

        public int SnakeLength {
            get;
            private set;
        }

        private double cummulativeAccuracy = 0;
        private double cummulativeRT = 0;

        public ScenarioData(string mirrorId, string scenarioId, int setLevel) {
            this.MirrorID = mirrorId;
            this.ScenarioID = scenarioId;
            this.SetLevel = setLevel;
        }

        public void AddRecord(int trialId, int accuracy, double rt){
            if (scenarioDict.ContainsKey(trialId)) {
                throw new Exception(String.Format("The trial with id '{0}' already exists.", trialId));
            }

            cummulativeAccuracy += accuracy;
            cummulativeRT += rt;

            ScenarioRecord record = new ScenarioRecord(trialId, accuracy, rt);

            this.scenarioRecords.Add(record);
            this.scenarioDict.Add(trialId, record);
        }

        public ScenarioRecord GetRecord() {
            if (this.usedIndex < this.scenarioRecords.Count - 1) {
                return this.scenarioRecords[++usedIndex];
            }
            else {
                return this.scenarioRecords[usedIndex];
            }
        }

        public ScenarioRecord GetRandomRecord() {
            return this.scenarioRecords[Program.rnd.Next(this.scenarioRecords.Count - 1)];
        }

        public int GetAvgRT() {
            return (int)cummulativeRT / scenarioRecords.Count;
        }

        public int GetAvgAccuracy() {
            double accuracy = (double)(cummulativeAccuracy / scenarioRecords.Count);
            if (accuracy > 0.5 && accuracy <= 1.0) {
                return 1;
            } else if (accuracy >= 0 && accuracy <= 0.5) {
                return 0;
            } else {
                throw new Exception("Invalid average accuracy");
            }
        }
    }

    class PlayerData 
    {
        // [TODO] access modifier to private
        private Dictionary<string, ScenarioData> scenarioDatabase = new Dictionary<string, ScenarioData>();

        public int PlayerID {
            get;
            private set;
        }

        public PlayerData(int playerId) {
            this.PlayerID = playerId;
        }

        public bool HasScenario(string scenarioId) {
            return this.scenarioDatabase.ContainsKey(scenarioId);
        }

        public ScenarioData AddScenario(string mirrorId, string scenarioId, int setLevel) {
            ScenarioData scenarioData;
            if (!this.scenarioDatabase.TryGetValue(scenarioId, out scenarioData)) {
                scenarioData = new ScenarioData(mirrorId, scenarioId, setLevel);
                scenarioDatabase.Add(scenarioId, scenarioData);
            }

            return scenarioData;
        }

        public ScenarioData GetScenario(string scenarioId) {
            ScenarioData scenarioData = null;
            this.scenarioDatabase.TryGetValue(scenarioId, out scenarioData);
            return scenarioData;
        }

        public ScenarioData GetScenario(int setLevel) {
            List<ScenarioData> matching = (from keyValuePair in this.scenarioDatabase
                                          where (keyValuePair.Value.SetLevel == setLevel)
                                          select keyValuePair.Value).ToList<ScenarioData>();

            if (matching.Count == 0) {
                return null;
            }
            else {
                return matching[Program.rnd.Next(matching.Count - 1)];
            }
        }
    }
}
