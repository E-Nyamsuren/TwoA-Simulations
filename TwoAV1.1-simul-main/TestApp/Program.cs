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
Filename: Program.cs
*/

#endregion Header

namespace TestApp
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Reflection;
    using System.Text;
    using System.Xml.Linq;
    using System.Diagnostics;

    using TwoA;
    using AssetPackage;
    using TileZero;

    partial class Program
    {
        static void Main (string[] args) {

            //doOneTwoThreeSimControl();

            //doOneTwoThreeSim("old");
            doOneTwoThreeSim();

            //doTileZeroSim();
            
            Console.ReadKey();
        }

        static void doTileZeroSim() {
            // [SC] find win rates of AI opponents playing against each ither
            evaluateTileZeroAIDifficulty();

            // [SC] Simulation 1
            doTileZeroFreqStabilitySimulation(OLD_OLD);
            // [SC] Simulation 2
            doTileZeroFreqStabilitySimulation(NEW_OLD);
            // [SC] Simulation 3
            doTileZeroFreqStabilitySimulation(NEW_NEW);

            // [SC] Simulation 4
            doTileZeroSimulation();
        }

        // [SC] prints a message to both console and debug output window
        static void printMsg(string msg) {
            Console.WriteLine(msg);
            Debug.WriteLine(msg);
        }
    }

    // [SC][2016.11.29] modified
    class MyBridge : IBridge, IDataStorage
    {
        // [SC] "TwoAAppSettings.xml" and "gameplaylogs.xml" are embedded resources
        // [SC] these XML files are for running this test only and contain dummy data
        // [SC] to use the TwoA asset with your game, generate blank XML files with the accompanying widget https://github.com/rageappliedgame/HATWidget
        public MyBridge() {}

        public bool Exists(string fileId) {
            Assembly assembly = Assembly.GetExecutingAssembly();
            string[] resourceNames = assembly.GetManifestResourceNames();
            return resourceNames.Contains<string>(Program.resourceNS + fileId);
        }

        public void Save(string fileId, string fileData) {
            // [SC] save is not implemented since the xml files are embedded resources
        }

        public string Load(string fileId) {
            Assembly assembly = Assembly.GetExecutingAssembly();
            using (Stream stream = assembly.GetManifestResourceStream(Program.resourceNS + fileId)) {
                using (StreamReader reader = new StreamReader(stream)) {
                    return reader.ReadToEnd();
                }
            }
        }

        public String[] Files() {
            return null;
        }

        public bool Delete(string fileId) {
            return false;
        }
    }
}
