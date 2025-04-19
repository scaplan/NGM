/*
*  Spencer Caplan
*/

import java.util.*;

public class Feature {
	
	private String myName = "";
	private String myLevel = "";
	private double myProminence = 0.0;
	private boolean isNull = true;

	private static double salienceDistributionStdDev;
	
	private static double otherProminence;
	private static double basicProminence;
	
	public Feature() {
		
	}
	
	public Feature(String name, String level) {
		myName = name;
		myLevel = level;
		isNull = false;
	}
	
	public static void setClassProminenceLevels(double otherLevel, double basicLevel) {
		otherProminence = otherLevel;
		basicProminence = basicLevel;
	}

	public static void setSalienceStandardDev(double stdDevToSet) {
		salienceDistributionStdDev = stdDevToSet;
	}
	
	public double sampleSalienceInstance() {
		Random r = new Random();
		double mySample = r.nextGaussian()*salienceDistributionStdDev;
		if (myLevel.equals("basic")) {
			mySample = mySample + basicProminence;
		} else {
			mySample = mySample + otherProminence;
		}

		if (mySample > 1.0) {
			mySample = 1.0;
		} else if (mySample < 0.0) {
			mySample = 0.0;
		}
		return mySample;
	}

	public void setProminence(double prominence) {
		myProminence = prominence;
	}

	public double getProminence() {
		return myProminence;
	}
	
	public String getLevel() {
		return myLevel;
	}
	
	public String getName() {
		return myName;
	}
	
	public boolean checkNull(){
		if (isNull) {
			return true;
		} else {
			return false;
		}
	}
	
}
