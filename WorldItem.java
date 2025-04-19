/*
*  Spencer Caplan
*/

import java.util.*;

public class WorldItem {
	
	private String myName = "";
	private List<Feature> myFeatures = new ArrayList<Feature>();
	private String levelHome = "";
	
	public WorldItem(String name) {
		myName = name;
	}
	
	/*
	 * For making a shallow copies of an existing WorldItem object
	 */
	public WorldItem(WorldItem toCopy) {
		myName = toCopy.getName();
		myFeatures = new ArrayList<Feature>(toCopy.getFeatures());
		levelHome = toCopy.getLevelHome();
	}

	public String toString() {
		return myName;
	}

	public void setLevelHome(String toSet) {
		levelHome = toSet;
	}
	
	public void addFeature(Feature toAdd) {
		myFeatures.add(toAdd);
	}

	public String getSuperFeatureName() {
		for (Feature currFeature : myFeatures) {
			if (currFeature.getLevel().equals("super")) {
				return currFeature.getName();
			}
		}
		return "";
	}
	
	public List<Feature> getFeatures() {
		return myFeatures;
	}
	
	public Map<String, Feature> getFeatureMap() {
		Map<String, Feature> toReturn = new HashMap<String, Feature>();
		for (ListIterator<Feature> iter = myFeatures.listIterator(); iter.hasNext(); ) {
			Feature currFeature = iter.next();
			toReturn.put(currFeature.getName(), currFeature);
		}
		return toReturn;
	}

	public String getLevelHome() {
		return levelHome;
	}
	
	public String getName() {
		return myName;
	}
	
	public void printFeatures() {
		System.out.println("Features for " + myName + ": ");
		System.out.println("----------");
		for (ListIterator<Feature> iter = myFeatures.listIterator(); iter.hasNext(); ) {
			Feature currFeature = iter.next();
			System.out.println(currFeature.getName() + " : " + currFeature.getLevel());
		}
		System.out.println("");
	}
	
	public void printFeaturesCompact() {
		System.out.print(myName + ":");
		for (ListIterator<Feature> iter = myFeatures.listIterator(); iter.hasNext(); ) {
			Feature currFeature = iter.next();
			System.out.print("(" + currFeature.getName() + "," + currFeature.getLevel() + "),");
		}
		System.out.println();
	}
	
}
