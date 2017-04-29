package converter;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class FormatConverterResults {

	public static void main(String[] args) {

		boolean isFirst = true, hasPredecessor = false;
		File result = new File("RESULTS.txt");
		int tweetID = 2816;
		try (BufferedReader partBF = new BufferedReader(
				new FileReader(new File("../NER_Project/src/test_set_results.txt")))) {
			BufferedWriter bw = new BufferedWriter(new FileWriter(result));
			String line;
			String[] tokens;
			while ((line = partBF.readLine()) != null) {
				if (isFirst) {
					bw.append(tweetID + "\t");
					isFirst = false;
				}
				if (line.compareTo("") != 0) {
					tokens = line.split("\t");
					if (tokens[2].compareTo("O") != 0)
						if (hasPredecessor)
							bw.append(";" + tokens[2] + "/" + tokens[0]);
						else {
							bw.append(tokens[2] + "/" + tokens[0]);
							hasPredecessor = true;
						}
				} else // end of tweet
				{
					bw.append("\n");
					isFirst = true;
					tweetID++;
					hasPredecessor = false;
				}
			}
			bw.close();

		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}
