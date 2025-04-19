/*
*  Spencer Caplan
*/

import java.io.*;
import java.util.*;
import java.util.Map.Entry;

public class LocalWordLearner {
	
	/*
	 * Retained across trials
	 */
	private static List<WorldItem> itemsList = new ArrayList<>();
	private static Map<String, List<WorldItem>> levelToEvalItemsMap = new HashMap<>();
	private static Map<String, WorldItem> nameToItemMap = new HashMap<>();
	private static Map<String, Map<String, Integer>> resultsMap = new HashMap<>();
	private static Map<String, Map<String, Double>> xTresultsMap = new HashMap<>();
	private static Map<String, Map<String, ArrayList<Double>>> xTresultsMapList = new HashMap<>();
	private static Map<String, Integer> testTypeToNumberMap = new HashMap<>();
	private static int numTotalTrials;
	private static double distanceThreshold;
	private static String outputFileName;
	private static String outputFileNameByIndividual;
	private static double sequentialComparisonProbability;
	private static boolean useConstrastComparisonFlag;
	
	/*
	 * Reset between trials
	 */
	private static List<WordRepresentation> representationList = new ArrayList<>();
	private static Map<String, WordRepresentation> labelToRepresentationMap = new HashMap<>();

	private static Map<String, Map<String, Double>> xTresultsMapIndividualParticipant = new HashMap<>();
	private static Map<String, Integer> testTypeToNumberMapIndividualParticipant = new HashMap<>();
	
	public static void main(String[] args) throws IOException {
		if (args.length < 9) {
			System.out.println("Given " + args.length + " input arguments");
			throw new IllegalArgumentException("Incorrect number of arguments");
		}
		String worldFile = args[0];
		String trainTestFile = args[1];
		int numTotalTrials = Integer.parseInt(args[2]);
		// set feature prominence levels
		Feature.setClassProminenceLevels(Double.parseDouble(args[3]), Double.parseDouble(args[4]));
		WordRepresentation.setBlockingThreshold(Double.parseDouble(args[5]));
		distanceThreshold = Double.parseDouble(args[6]);
		Feature.setSalienceStandardDev(Double.parseDouble(args[7]));
		outputFileName = args[8];
		outputFileNameByIndividual = outputFileName + "_byIndividual.txt";
		PrintWriter pw = new PrintWriter(outputFileNameByIndividual);
		pw.write("Participant,Proportion,Single,Sub_seq,Basic_seq,Super_seq,Sub_par,Basic_par,Super_par\n");
		pw.close();

		if (args.length == 10){
			sequentialComparisonProbability = Double.parseDouble(args[9]);
			useConstrastComparisonFlag = true;
		} else {
			useConstrastComparisonFlag = false;
		}
		
		loadItemsFromFile(worldFile);

		int trialsFinished = 0;
		while (trialsFinished < numTotalTrials) {
			runTrial(trainTestFile);
			// Call function which prints current trial participant means (standard error can be calculated over those means)
			printResultsXTByIndividual(trialsFinished);
			resetLeanerMemory();
			trialsFinished++;
		}
		
		printResultsXT(); //FixDec
	}
	
	private static double computeXTresults(String objectClass, List<WorldItem> selectedItems, String levelToCheck) {
		// passing in the training item(s), selected items, and level
		// return the proportion of test grid objects for the given level which are included in "picked out items"

		List<WorldItem> goldStandardAllTypes = levelToEvalItemsMap.get(levelToCheck);
		List<String> goldStandardThisType = new ArrayList<>();
		for (WorldItem currItem : goldStandardAllTypes){
			Map<String, Feature> currFeatures = currItem.getFeatureMap();
			if (currFeatures.containsKey(objectClass)){
				String currName = currItem.getName();
				goldStandardThisType.add(currName);
			}
		}

		int numGoldStdItems = goldStandardThisType.size();
		int numMatches = 0;
		for (WorldItem currSelectedItem : selectedItems) {
			if (goldStandardThisType.contains(currSelectedItem.getName())) {
				numMatches++;
			}
		}
		double proportionMatrch = (numMatches / (double) numGoldStdItems);
		return proportionMatrch;
	}
	

	private static void printResultsXT() throws IOException {
		try( BufferedWriter bw = new BufferedWriter(new FileWriter(outputFileName)) ) {
			bw.write("Proportion,Single,Sub_seq,Basic_seq,Super_seq,Sub_par,Basic_par,Super_par\n");
			String[] levelOrder = {"SUBORDINATE", "BASIC", "SUPERORDINATE"};
			String[] testTypeOrder = {"single", "three_sub_sequence", "three_basic_sequence", "three_super_sequence", "three_sub_parallel", "three_basic_parallel", "three_super_parallel"};
			for (int n = 0; n < levelOrder.length; n ++) {
				String level = levelOrder[n];
				String levelName = n + "_" + level;
				bw.write(levelName + "");
				for (String testType : testTypeOrder) {
					double trialsDenom = (double) testTypeToNumberMap.get(testType);
					Map<String, Double> currTypeResults = xTresultsMap.get(testType);
					double value = 0.0;
					if (currTypeResults != null) {
						if (currTypeResults.containsKey(level)) {
							value = currTypeResults.get(level);
						}
						double currResult = (value / trialsDenom);
						bw.write("," + String.format( "%.3f", currResult ));
					}
				}
				bw.newLine();
			}
			bw.close();
		}
		for (String testType : xTresultsMap.keySet()) {
			Map<String, Double> currTypeResults = xTresultsMap.get(testType);
		//	Map<String, ArrayList<Double>> currTypeResultsArray = xTresultsMapList.get(testType);
			double trialsDenom = (double) testTypeToNumberMap.get(testType);
			for (Entry<String, Double> entry : currTypeResults.entrySet()) {
				double value = 0.0;
				if (entry.getValue() != null) {
					value = entry.getValue();
				}

				double currResult = (value / trialsDenom);
			}
		}
	}

	private static void printResultsXTByIndividual(int participantNumber) throws IOException {
		try( BufferedWriter bw = new BufferedWriter(new FileWriter(outputFileNameByIndividual, true)) ) {
			String[] levelOrder = {"SUBORDINATE", "BASIC", "SUPERORDINATE"};
			String[] testTypeOrder = {"single", "three_sub_sequence", "three_basic_sequence", "three_super_sequence", "three_sub_parallel", "three_basic_parallel", "three_super_parallel"};
			for (int n = 0; n < levelOrder.length; n ++) {
				String level = levelOrder[n];
				String levelName = n + "_" + level;
				bw.write(participantNumber + "," + levelName + "");
				for (String testType : testTypeOrder) {
					double trialsDenom = (double) testTypeToNumberMapIndividualParticipant.get(testType);
					Map<String, Double> currTypeResults = xTresultsMapIndividualParticipant.get(testType);
					double value = 0.0;
					if (currTypeResults != null) {
						if (currTypeResults.containsKey(level)) {
							value = currTypeResults.get(level);
						}
						double currResult = (value / trialsDenom);
						bw.write("," + String.format( "%.3f", currResult ));
					}
				}
				bw.newLine();
			}
			bw.close();
		}
	}
	
	private static void resetLeanerMemory() {
		representationList = new ArrayList<>();
		labelToRepresentationMap = new HashMap<>();
		xTresultsMapIndividualParticipant = new HashMap<>();
		testTypeToNumberMapIndividualParticipant = new HashMap<>();
	}
	
	private static void updateResultsMap(String level, String testType) {
		if (resultsMap.containsKey(testType)) {
			Map<String, Integer> currResults = resultsMap.get(testType);
			int previousCount;
			if (currResults.containsKey(level)) {
				previousCount = currResults.get(level);
			} else {
				previousCount = 0;
			}
			previousCount++;
			currResults.put(level, previousCount);
			resultsMap.put(testType, currResults);
		} else {
			Map<String, Integer> currResults = new HashMap<>();
			currResults.put(level, 1);
			resultsMap.put(testType, currResults);
		}
	}

	private static void updateResultsMapXTscoring(String testType, String categoryType, double valueToAdd) {

		// Map<String, Map<String, Integer>> xTresultsMap
		Map<String, Double> currTypeMap;
		Map<String, ArrayList<Double>> currTypeMapArray;
		if (xTresultsMap.containsKey(testType)) {
			currTypeMap = xTresultsMap.get(testType);
			currTypeMapArray = xTresultsMapList.get(testType);
		} else {
			currTypeMap = new HashMap<>();
			xTresultsMap.put(testType, currTypeMap);
			currTypeMapArray = new HashMap<>();
			xTresultsMapList.put(testType, currTypeMapArray);
		}

		Map<String, Double> currTypeMapIndividual;
		if (xTresultsMapIndividualParticipant.containsKey(testType)) {
			currTypeMapIndividual = xTresultsMapIndividualParticipant.get(testType);
		} else {
			currTypeMapIndividual = new HashMap<>();
			xTresultsMapIndividualParticipant.put(testType, currTypeMapIndividual);
		}

		double prevValue = 0.0;
		ArrayList<Double> prevValueArray = new ArrayList<Double>();
		if (currTypeMap.containsKey(categoryType)) {
			prevValue = currTypeMap.get(categoryType);
	//		System.out.println("Accesing prevMapArray");
			prevValueArray = currTypeMapArray.get(categoryType);
		}
		currTypeMap.put(categoryType, (prevValue + valueToAdd));

		double prevValueIndividual = 0.0;
		if (currTypeMapIndividual.containsKey(categoryType)) {
			prevValueIndividual = currTypeMapIndividual.get(categoryType);
		}
		currTypeMapIndividual.put(categoryType, (prevValueIndividual + valueToAdd));
		
		
		prevValueArray.add(valueToAdd);
		currTypeMapArray.put(categoryType, prevValueArray);
	}
	
	private static List<WorldItem> pickOutLikeItems(String label) throws IllegalStateException{
		if (!labelToRepresentationMap.containsKey(label)) {
			throw new IllegalStateException();
		}
		
		WordRepresentation currRepresentation = labelToRepresentationMap.get(label);
		
		List<WorldItem> pickedOutItems = new ArrayList<>();
		for (ListIterator<WorldItem> iter = itemsList.listIterator(); iter.hasNext(); ) {
			WorldItem currItemSafeCopy = new WorldItem(iter.next());
			double currItemDistance = itemRepDistance(currRepresentation, currItemSafeCopy);
			if (currItemDistance <= distanceThreshold) {
				pickedOutItems.add(currItemSafeCopy);
			}
		}
		return pickedOutItems;
	}
	
	private static double itemRepDistance(WordRepresentation currRep, WorldItem item) {

		// iterate over all features present in currRep -- sum difference between them and itemFeatures
		double currDistance = 0.0;

		Map<String, Feature> realItemComparisonMap = item.getFeatureMap();
		Map<String, Feature> repFeatures = currRep.getFeatures();
		for (String featName : repFeatures.keySet()) {
			if (!realItemComparisonMap.containsKey(featName)) {
				double currFeatProminence = (repFeatures.get(featName)).getProminence();
				currDistance = currDistance + currFeatProminence;
			}
		}
		return currDistance;
	}

	private static WordRepresentation createRep(String label, List<WorldItem> items) {
		WordRepresentation repToCreate = new WordRepresentation(label);
		for (WorldItem currItem : items) {
			List<Feature> allFeatures =  currItem.getFeatures();
			for (Feature currFeature : allFeatures) {
				// for each feature for that object: sample from salience distribution and put in rep
				double currSalience = currFeature.sampleSalienceInstance();
				Feature featToAdd = new Feature(currFeature.getName(), currFeature.getLevel());

				// need to check if feature already present -- and add salience accordingly
				currSalience = currSalience + repToCreate.checkContains(currFeature.getName());
				if (currSalience > 1.0) {
					currSalience = 1.0;
				}
				featToAdd.setProminence(currSalience);
				
				repToCreate.addFeature(featToAdd);
			}
		}
		return repToCreate;
	}


	private static void trainingTrial(String label, List<WorldItem> items) {

		WordRepresentation currRepresentation;
		if (!labelToRepresentationMap.containsKey(label)) {
			// New label
			
			currRepresentation = createRep(label, items);
			representationList.add(currRepresentation);
			labelToRepresentationMap.put(label, currRepresentation);
		} else {
			// Evaluating existing label against object
			currRepresentation = labelToRepresentationMap.get(label);

			// call distance function to see if presented object is consistent with curr rep
			// if so then do nothing here
			boolean consistentWithRep = true;
			for (ListIterator<WorldItem> iter = items.listIterator(); iter.hasNext(); ) {
				WorldItem currItemSafeCopy = new WorldItem(iter.next());
				double currItemDistance = itemRepDistance(currRepresentation, currItemSafeCopy);
				if (currItemDistance > distanceThreshold) {
					consistentWithRep = false;
				}
			}

			if (!consistentWithRep) {
				// if not then use that object to create new rep and fold it in
				WordRepresentation newRep = createRep(label, items);
				currRepresentation.combineRep(newRep.getFeatures());
			} else {
				if (useConstrastComparisonFlag) {
					// probabilistically sample in new features (wrt sequentialComparisonProbability)
					double currComparisonProbability = Math.random();
					if (currComparisonProbability < sequentialComparisonProbability) {
						WordRepresentation newRep = createRep(label, items);
						currRepresentation.combineRepAdditive(newRep.getFeatures());
					}
				} 
				// else do nothing (Basic implementation with no contrast comparison parameter)
			}
		}

		// check blocking threshold and edit rep accordingly
		currRepresentation.clearBlockedFeatures();
	}

	private static String getCategoryType(List<WorldItem> selectedItems) {
		String categoryLabel = "";
		boolean multipleCategories = false;
		for (WorldItem currItem : selectedItems) {
			String currCategory = currItem.getSuperFeatureName();
			if (categoryLabel.equals("")) {
				categoryLabel = currCategory;
			} else {
				if (!categoryLabel.equals(currCategory)) {
					multipleCategories = true;
				}
			}
		}
		return categoryLabel;
	}

	private static void runTestOnLabel(String label, String testType) {
		List<WorldItem> allTheLikeItems = pickOutLikeItems(label);
		for (ListIterator<WorldItem> iter = allTheLikeItems.listIterator(); iter.hasNext(); ) {
			WorldItem currLikeItem = iter.next();
		}

		String categoryLabel = getCategoryType(allTheLikeItems);

		String[] categoryLevels = {"SUBORDINATE", "BASIC", "SUPERORDINATE"};
		for (String categoryLevel : categoryLevels) {
			double levelProp = computeXTresults(categoryLabel, allTheLikeItems, categoryLevel);
			if (levelProp > 0.0) {
				updateResultsMapXTscoring(testType, categoryLevel, levelProp);
			}
		}

		if (testTypeToNumberMap.containsKey(testType)) {
			int prevCount = testTypeToNumberMap.get(testType);
			testTypeToNumberMap.put(testType, prevCount + 1);
		} else {
			testTypeToNumberMap.put(testType, 1);
		}

		if (testTypeToNumberMapIndividualParticipant.containsKey(testType)) {
			int prevCount = testTypeToNumberMapIndividualParticipant.get(testType);
			testTypeToNumberMapIndividualParticipant.put(testType, prevCount + 1);
		} else {
			testTypeToNumberMapIndividualParticipant.put(testType, 1);
		}
		
	}

	private static void runTrial(String trainTestFileSource) throws IOException {

		List<List<String>> testLines = new ArrayList<>();
		try( BufferedReader br = new BufferedReader(new FileReader(trainTestFileSource)) ) {
			String currLine;
			List<String> trialGroup = new ArrayList<>();
			while ((currLine = br.readLine()) != null) {
				trialGroup.add(currLine);
				if (currLine.contains(";")) {
					testLines.add(trialGroup);
					trialGroup = new ArrayList<>();
				}
			}
		}
		
		for (List<String> currGroup : testLines) {
			for (String currLine : currGroup) {
				String[] testTypeSplit = {};
		    	String testType = "";
		    	String labelAndObjects = "";
		    	if (currLine.contains(";")) {
		    		testTypeSplit = currLine.split(";");
		    		testType = testTypeSplit[1];
		    		labelAndObjects = testTypeSplit[0];
		    	} else {
		    		labelAndObjects = currLine;
		    	}

		    	String[] labelAndObjectsArray = labelAndObjects.split(":");
		    	String label = labelAndObjectsArray[0];
		    	String[] objectSet = labelAndObjectsArray[1].split(",");
		    	List<WorldItem> itemsList = new ArrayList<>();
	    		for (String objectname : objectSet) {
	    			WorldItem currItem = nameToItemMap.get(objectname);
	    			itemsList.add(currItem);
	    		}

	    		// Call training trial to update mental representation
	    		// In parallel case then itemsList contains all the items to add over
	    		// In sequential case then trainingTrial will check if current rep is 
	    		// compatible with input before choosing to alter rep
	    		trainingTrial(label, itemsList);
	    		if (!testType.isEmpty()) {
	    			runTestOnLabel(label, testType);
	    		}	
			}
		}

	}
	
	private static void loadItemsFromFile(String worldFileSource) throws IOException {

		try( BufferedReader br = new BufferedReader(new FileReader(worldFileSource)) ) {
		    String currLine = br.readLine();
		    while (currLine != null) {
		    	String[] nameAndAssocFeatures = currLine.split(":");
		    	String currName = nameAndAssocFeatures[0];
		    	String currFeaturesTotal = nameAndAssocFeatures[1];
		    	String levelHome = nameAndAssocFeatures[2];
		    	WorldItem buildingItem = new WorldItem(currName);
		    	buildingItem.setLevelHome(levelHome);
		    	String[] currFeaturePairs = currFeaturesTotal.split("[)],");
		    	for (String pair : currFeaturePairs) {
		    		pair = pair.replace(")", "");
		    		pair = pair.replace("(", "");
		    		pair = pair.replaceAll(" ", "");
		    		String[] featureLevelPair = pair.split(",");
		    		String featureName = featureLevelPair[0];
		    		String featureLevel = featureLevelPair[1];
		    		Feature currFeature = new Feature(featureName, featureLevel);
		    		if (!currFeature.checkNull()){
		    			buildingItem.addFeature(currFeature);
		    		}
		    	}
		    	//buildingItem.printFeatures();
		    	itemsList.add(buildingItem);
		    	nameToItemMap.put(currName, buildingItem);
		    	currLine = br.readLine();
		    }
		}

		List<WorldItem> evalSubItems = new ArrayList<>();
		List<WorldItem> evalBasicItems = new ArrayList<>();
		List<WorldItem> evalSuperItems = new ArrayList<>();
		for (WorldItem currItem : itemsList) {
			String currLevelHome = currItem.getLevelHome();
			if (currLevelHome.equals("SUBORDINATE")) {
				evalSubItems.add(currItem);
			} else if (currLevelHome.equals("BASIC")) {
				evalBasicItems.add(currItem);
			} else if (currLevelHome.equals("SUPERORDINATE")) {
				evalSuperItems.add(currItem);
			} else {
				System.out.println("Object not properly specified for levelHome!");
				throw new IllegalStateException();
			}
		}
		levelToEvalItemsMap.put("SUBORDINATE", evalSubItems);
		levelToEvalItemsMap.put("BASIC", evalBasicItems);
		levelToEvalItemsMap.put("SUPERORDINATE", evalSuperItems);

	}

}
