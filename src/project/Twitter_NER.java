/**
 * @author Burak Mandira
 * @date Apr 4, 2017
 *
 */
package project;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.util.List;
import java.util.Properties;

import edu.stanford.nlp.ie.AbstractSequenceClassifier;
import edu.stanford.nlp.ie.crf.CRFClassifier;
import edu.stanford.nlp.ling.CoreLabel;
import edu.stanford.nlp.util.Triple;

public class Twitter_NER {
	public static void main(String[] args) {

		// no need to call trainClassifier(). It contains training phase
		// runCrossValidation(2);

		// need to call trainClassifier() first and then runClassifier()
		trainClassifier();
		runClassifier();
	}

	public static void runClassifier() {
		try {
			CRFClassifier<CoreLabel> classifier = CRFClassifier.getClassifier("./src/finalClassifier.ser.gz");

			System.setOut(
					new PrintStream(new BufferedOutputStream(new FileOutputStream("./src/test_set_results.txt"))));
			classifier.classifyAndWriteAnswers("./CoNLL_test.tsv", false);

		} catch (IOException | ClassCastException | ClassNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void trainClassifier() {
		BufferedReader bf;
		try {
			bf = new BufferedReader(new FileReader(new File("./src/twitter.prop")));
			Properties prop = new Properties();
			prop.load(bf);
			bf.close();

			CRFClassifier<CoreLabel> classifier = new CRFClassifier<>(prop);
			classifier.train();
			classifier.serializeClassifier("./src/finalClassifier.ser.gz");

		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void runCrossValidation(int K) {
		int linesFile = 52523; // toChange if we take another file
		int k = K;
		Double P = 0.0, R = 0.0, F1 = 0.0;
		for (int i = 0; i < k; ++i) {
			try {
				// partitioning
				int indexLine = 0;
				BufferedWriter bfTest = new BufferedWriter(new FileWriter(new File("./src/testSet.txt")));
				BufferedWriter bfTrain = new BufferedWriter(new FileWriter(new File("./src/trainSet.tsv")));

				BufferedReader partBF = new BufferedReader(new FileReader(new File("./src/CoNLL_final.tsv")));
				String line;
				while ((line = partBF.readLine()) != null) {
					indexLine++;
					if (indexLine > (linesFile / k) * i && indexLine < (linesFile / k) * (i + 1))
						bfTest.write(line + "\n");
					else
						bfTrain.write(line + "\n");
				}

				bfTest.close();
				bfTrain.close();
				partBF.close();

				// classifying
				BufferedReader bf = new BufferedReader(new FileReader(new File("./src/twitter_old.prop")));
				Properties prop = new Properties();
				prop.load(bf);
				bf.close();

				CRFClassifier<CoreLabel> classifier = new CRFClassifier<>(prop);
				classifier.train();
				classifier.serializeClassifier("./src/tempClassifier.ser.gz");

				System.setOut(new PrintStream(new BufferedOutputStream(new FileOutputStream("./src/temp.txt"))));
				Triple<Double, Double, Double> stats = classifier.classifyAndWriteAnswers("./src/testSet.txt ", true);
				P += stats.first;
				R += stats.second;
				F1 += stats.third;
				System.err.println("i = " + (i + 1));

			} catch (IOException | ClassCastException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		System.err.println("P: " + P / k);
		System.err.println("R: " + R / k);
		System.err.println("F1: " + F1 / k);
	}
}
