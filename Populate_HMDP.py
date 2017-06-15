import pyodbc
import csv
import os
from functools import reduce
import argparse

# Create parser to receive instructions from command line
parser = argparse.ArgumentParser(description = 'Input arguments to populate database')
# Argument to create table and whether to create new table
parser.add_argument('-t', '--tablename', action = 'store', help = "Table for inserting data", default = "HMDP_OBESITY_TRAITS")
parser.add_argument('-c', '--create', action = 'store_true', help = "Create table", default= False) 
# Argument to specify path
parser.add_argument('-p', '--path', action = 'store', help = "Directory path with txt file", default=".")
# Argument to specify database
parser.add_argument('-db', '--database', action = 'store', help="Database to be opened", default = "HMDP")
# Parse all the the arguments together
args = parser.parse_args()
# Tokenize each argument into variables
tablename = args.tablename
create = args.create
path = args.path
database = args.database

# method to create table if needed
def createTable(database, tablename):
	global cursor
	
	query = "create table {!s} ".format(tablename) + "(" \
			"MouseID char(50)," \
			" Strain char(50)," \
			" Sex char(10)," \
			" Weight_0_wks_diet float," \
			" Weight_2_wks_diet float," \
			" Weight_4_wks_diet float," \
			" Weight_6_wks_diet float," \
			" Weight_8_wks_diet float," \
			" SAC_weight float," \
			" NMR_Fat_Mass_0_wks_diet float," \
			" NMR_Fat_Mass_2_wks_diet float," \
			" NMR_Fat_Mass_4_wks_diet float," \
			" NMR_Fat_Mass_6_wks_diet float," \
			" NMR_Fat_Mass_8_wks_diet float," \
			" NMR_Lean_Mass_0_wks_diet float," \
			" NMR_Lean_Mass_2_wks_diet float," \
			" NMR_Lean_Mass_4_wks_diet float," \
			" NMR_Lean_Mass_6_wks_diet float," \
			" NMR_Lean_Mass_8_wks_diet float," \
			" NMR_Free_Fluid_0_wks_diet float," \
			" NMR_Free_Fluid_2_wks_diet float," \
			" NMR_Free_Fluid_4_wks_diet float," \
			" NMR_Free_Fluid_6_wks_diet float," \
			" NMR_Free_Fluid_8_wks_diet float," \
			" AVG_Food_Intake_4_wks_diet float," \
			" Food_Intake_Day1 float," \
			" Food_Intake_Day2 float," \
			" Food_Intake_Day3 float," \
			" Food_Intake_Day4 float," \
			" Liver_Wt float," \
			" Spleen_Wt float," \
			" Kidney_Wt float," \
			" Heart_Wt float," \
			" Lung_Wt float," \
			" SubQ_Fat_Wt float," \
			" Gonadal_Fat_Wt float," \
			" Retroperitoneal_Fat_Wt float," \
			" Mesenteric_Fat_Wt float," \
			" RBC float," \
			" MCV float," \
			" HCT float," \
			" MCH float," \
			" MCHC float," \
			" RDW_percent float," \
			" RDWa float," \
			" PLT float," \
			" MPV float," \
			" HGB float," \
			" WBC float," \
			" LYM float," \
			" MONO float," \
			" GRAN float," \
			" LYM_percent float," \
			" MONO_percent float," \
			" GRAN_percent float," \
			" Trigly float," \
			" Tot_chol float," \
			" HDL float," \
			" UC float," \
			" FFA float," \
			" Glucose float," \
			" Insulin float," \
			" Glycerol float," \
			" LDL float," \
			" Esterified_Chol float," \
			" NMR_Total_Mass_0_wks float," \
			" NMR_Total_Mass_2_wks float," \
			" NMR_Total_Mass_4_wks float," \
			" NMR_Total_Mass_6_wks float," \
			" NMR_Total_Mass_8_wks float," \
			" NMR_Total_Mass_0to2_wks float," \
			" NMR_Total_Mass_0to4_wks float," \
			" NMR_Total_Mass_0to6_wks float," \
			" NMR_Total_Mass_0to8_wks float," \
			" NMR_Total_Mass_2to4_wks float," \
			" NMR_Total_Mass_2to6_wks float," \
			" NMR_Total_Mass_2to8_wks float," \
			" NMR_Total_Mass_4to6_wks float," \
			" NMR_Total_Mass_4to8_wks float," \
			" NMR_Total_Mass_6to8_wks float," \
			" NMR_Total_Mass_Percent_Growth_0to2_wks float," \
			" NMR_Total_Mass_Percent_Growth_0to4_wks float," \
			" NMR_Total_Mass_Percent_Growth_0to6_wks float," \
			" NMR_Total_Mass_Percent_Growth_0to8_wks float," \
			" NMR_Total_Mass_Percent_Growth_2to4_wks float," \
			" NMR_Total_Mass_Percent_Growth_2to6_wks float," \
			" NMR_Total_Mass_Percent_Growth_2to8_wks float," \
			" NMR_Total_Mass_Percent_Growth_4to6_wks float," \
			" NMR_Total_Mass_Percent_Growth_4to8_wks float," \
			" NMR_Total_Mass_Percent_Growth_6to8_wks float," \
			" NMR_BFPercentage_0wks float," \
			" NMR_BFPercentage_2wks float," \
			" NMR_BFPercentage_4wks float," \
			" NMR_BFPercentage_6wks float," \
			" NMR_BFPercentage_8wks float," \
			" BF_response_0to2wks float," \
			" BF_response_0to4wks float," \
			" BF_response_0to6wks float," \
			" BF_response_0to8wks float," \
			" BF_response_2to4wks float," \
			" BF_response_2to6wks float," \
			" BF_response_2to8wks float," \
			" BF_response_4to6wks float," \
			" BF_response_4to8wks float," \
			" BF_response_6to8wks float," \
			" BF_Percent_Growth_0to2wks float," \
			" BF_Percent_Growth_0to4wks float," \
			" BF_Percent_Growth_0to6wks float," \
			" BF_Percent_Growth_0to8wks float," \
			" BF_Percent_Growth_2to4wks float," \
			" BF_Percent_Growth_2to6wks float," \
			" BF_Percent_Growth_2to8wks float," \
			" BF_Percent_Growth_4to6wks float," \
			" BF_Percent_Growth_4to8wks float," \
			" BF_Percent_Growth_6to8wks float," \
			" Liver_NMR_Mass_8wks float," \
			" Spleen_NMR_Mass_8wks float," \
			" Kidney_NMR_Mass_8wks float," \
			" Heart_NMR_Mass_8wks float," \
			" Lung_NMR_Mass_8wks float," \
			" SubQ_Fat_NMR_Mass_8wks float," \
			" Gonadal_Fat_NMR_Mass_8wks float," \
			" Retro_Fat_NMR_Mass_8wks float," \
			" Mesenteric_NMR_Mass_8wks float," \
			" Visceral float," \
			" Visceral_Fat_NMR_Mass_8wks float," \
			" Food_Intake_NMR_Mass_4wks float," \
			" Food_Intake_NMR_Mass_8wks float," \
			" HOMA_IR float," \
			" Fat_Mass_Response_0to2wks float," \
			" Fat_Mass_Response_0to4wks float," \
			" Fat_Mass_Response_0to6wks float," \
			" Fat_Mass_Response_0to8wks float," \
			" Fat_Mass_Response_2to4wks float," \
			" Fat_Mass_Response_2to6wks float," \
			" Fat_Mass_Response_2to8wks float," \
			" Fat_Mass_Response_4to6wks float," \
			" Fat_Mass_Response_4to8wks float," \
			" Fat_Mass_Response_6to8wks float," \
			" Fat_Mass_Percent_Growth_0to2wks float," \
			" Fat_Mass_Percent_Growth_0to4wks float," \
			" Fat_Mass_Percent_Growth_0to6wks float," \
			" Fat_Mass_Percent_Growth_0to8wks float," \
			" Fat_Mass_Percent_Growth_2to4wks float," \
			" Fat_Mass_Percent_Growth_2to6wks float," \
			" Fat_Mass_Percent_Growth_2to8wks float," \
			" Fat_Mass_Percent_Growth_4to6wks float," \
			" Fat_Mass_Percent_Growth_4to8wks float," \
			" Fat_Mass_Percent_Growth_6to8wks float);" 

	print(query)
	
	cursor.execute(query)
	cursor.commit()
	print("table %s successfully created in database %s" %(tablename, database))

# method to connect to the database
def createConnection(server, database):
	cn = pyodbc.connect('DRIVER={SQL Server}' + \
						';SERVER=' + server + \
						';DATABASE=' + database + \
						';Trusted_Connection= Yes')
	return cn

# "main" method which calls the functions and reads the txt file
if __name__ == '__main__':

	# connect to database
	cnxn = createConnection('PARKSLAB', database)
	print('connected to the database: %s successfully!' %database)
	cursor = cnxn.cursor()

	# if create is specified in the command line
	if create:
		createTable(database, tablename)

	# check if path exists
	if not os.path.isdir(path):
   		print('path does not exist')
		exit(1)

    # change directory
	os.chdir(path)

	fileNames = []

	# for each of the files in the dir ending with txt, add to the list
	for file in os.listdir(path):
		if file.endswith(".txt"):
			fileNames.append(file)

	for fileName in fileNames:

		print("Reading from:" + str(fileName))

		with open(fileName, 'r') as txtFile:

			txtReader = csv.reader(txtFile, delimiter = '\t')

			# Skip through the description header after the [Data] section 
			fileFormat = next(txtReader)

			index = 0
			# Resort each row to resemble the database format
			for rows in txtReader:

				index = index + 1
			
				list = []

				for cols in rows:
					list.append(cols)

				for i in range(0, len(list)):
					if list[i] == 'NA':
						list[i] = 'NULL'			

				try:
					query = "insert into dbo.{!s}".format(tablename) +\
						" values ({!r}, {!r}, {!r}, ".format(list[0], list[1], list[2])

					for j in range(3, (len(list) - 1)):
						query += (list[j] + ", ")	

					query += list[len(list) - 1]
					query += ");"
					
					cursor.execute(query)
					cursor.commit()

				# write errmsg if file I/O exception
				except Exception as eex:
					errmsg = "Warning: Value Error in " + str(fileName) + ", primary key is: {!r}, {!r}".format(list[0], list[1]) + ", the line is: " + str(counter)
					f = open("GC_{!r}_err.txt".format(tablename), "w")
					f.write(errmsg + "\n")
					f.write(list)
					f.close()

				else:
					print("Insert " + str(index) + " was successful!")

	cursor.commit()
	print("File Read Done!" + str(fileName))
	cnxn.close()
