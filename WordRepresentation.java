/*
*  Spencer Caplan
*/

import java.util.*;
import java.util.Map.Entry;

public class WordRepresentation {
	
	private String myName = "";
	private Map<String, Feature> myFeatures = new HashMap<String, Feature>();
	private Map<String, Feature> levelToFeatureMap = new HashMap<String, Feature>();
	private Map<String, String> levelToFeatureStringNameMap = new HashMap<String, String>();

	private static double lowerBlockingThreshold;
	
	public WordRepresentation(String name) {
		myName = name;
	}
	
	public String getName() {
		return myName;
	}

	public static void setBlockingThreshold(double cutoff) {
		lowerBlockingThreshold = cutoff;
	}
	
	public void printRepresentation() {
		System.out.println("Representation for label " + myName + ": ");
		System.out.println("----------");
		for (String name : myFeatures.keySet()) {
			System.out.println(name + " " + (myFeatures.get(name)).getProminence());
		}
	}

	public void clearBlockedFeatures() throws IllegalStateException{
		// iterate over the features in currRep -- if there exists more than one feature at a given level then deal with it
		String basicName = "";
		String subName = "";
		String superName = "";
		Map<String, Feature> safeCopyMyFeatures = new HashMap<String, Feature>(myFeatures);
		for (String currName : safeCopyMyFeatures.keySet()) {
			// check level
			String currLevel = (myFeatures.get(currName)).getLevel();
			List<String> toDelete = new ArrayList<String>();
			if (currLevel.equals("super")) {
				if (!superName.equals("")) {
					toDelete = checkFeatPair(safeCopyMyFeatures.get(currName), safeCopyMyFeatures.get(superName));
				} else {
					superName = currName;
				}
			} else if (currLevel.equals("basic")) {
				if (!basicName.equals("")) {
					toDelete = checkFeatPair(safeCopyMyFeatures.get(currName), safeCopyMyFeatures.get(basicName));
				} else {
					basicName = currName;
				}
			} else if (currLevel.equals("subordinate")) {
				if (!subName.equals("")) {
					toDelete = checkFeatPair(safeCopyMyFeatures.get(currName), safeCopyMyFeatures.get(subName));
				} else {
					subName = currName;
				}
			} else {
				System.out.println("Undefined Feature: " + currLevel);
				throw new IllegalStateException();
			}

			// remove whatever is in "toDelete"
			for (String featNameToRemove : toDelete) {
				// System.out.println(featNameToRemove + " was blocked in " + myName);
				myFeatures.remove(featNameToRemove);
			}
		}
	}
	
	private static List<String> checkFeatPair(Feature featOne, Feature featTwo) {
		double featOneProm = featOne.getProminence();
		double featTwoProm = featTwo.getProminence();
		List<String> blockedFeatures = new ArrayList<String>();

		if ((featOneProm >= lowerBlockingThreshold) && (featTwoProm >= lowerBlockingThreshold)) {
			blockedFeatures.add(featOne.getName());
			blockedFeatures.add(featTwo.getName());
		} else if ((featOneProm >= lowerBlockingThreshold) && (featTwoProm < lowerBlockingThreshold)) {
			blockedFeatures.add(featTwo.getName());
		} else if ((featOneProm < lowerBlockingThreshold) && (featTwoProm >= lowerBlockingThreshold)) {
			blockedFeatures.add(featOne.getName());
		}

		return blockedFeatures;
	}
	
	public void addFeature(Feature feat) {
		myFeatures.put(feat.getName(), feat);
	}

	public Map<String, Feature> getFeatures() {
		return myFeatures;
	}

	public void combineRep(Map<String, Feature> toAddIn) {
		for (String featName : toAddIn.keySet()) {
			Feature featToAdd = toAddIn.get(featName);
			this.addFeature(featToAdd);
		}
	}

	public void combineRepAdditive(Map<String, Feature> toAddIn) {
		for (String featName : toAddIn.keySet()) {
			Feature featToAdd = toAddIn.get(featName);
			double oldProminence = 0.0;
			if (myFeatures.containsKey(featName)) {
				oldProminence = (myFeatures.get(featName)).getProminence();
			}
			double newProminence = oldProminence + (featToAdd.getProminence());
			if (newProminence > 1.0) {
				newProminence = 1.0;
			}
			featToAdd.setProminence(newProminence);
			this.addFeature(featToAdd);
		}
	}

	public double checkContains(String featName) {
		if (myFeatures.containsKey(featName)) {
			return (myFeatures.get(featName)).getProminence();
		} else {
			return 0.0;
		}
	}

}
