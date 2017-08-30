import pyodbc
import csv
import os
from functools import reduce
import argparse

# Create parser to receive instructions from command line
parser = argparse.ArgumentParser(description = 'Input arguments to populate database')
# Argument to create table and whether to create new table
parser.add_argument('-t', '--tablename', action = 'store', help = "Table for inserting data", default = "Ref_Seq_GENE_ANNOTATION")
parser.add_argument('-c', '--create', action = 'store_true', help = "Create table", default= False) 
# Argument to specify path
parser.add_argument('-p', '--path', action = 'store', help = "Directory path with txt file", default="E:/GENE_ANNOTATION/Ref_Seq_Annotation")
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
	
	query = "create table {!s} ".format(tablename) + "(" + \
			"refSeqID varchar(100)," \
			" chromosome varchar(30)," \
			" strand char(1)," \
			" gene_Start int," \
			" gene_End int," \
			" gene varchar(50));"
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

		print("Reading from: " + str(fileName))

		with open(fileName, 'r') as txtFile:

			txtReader = csv.reader(txtFile, delimiter = '\t')

			errorCounter = 0

			index = 0
			# Resort each row to resemble the database format
			for rows in txtReader:

				index = index + 1

				list = []
				wanted = [1, 2, 3, 4, 5, 12]
				nonCharList = [5, 6]

				listCounter = 0

				for cols in rows[0:]:
					if listCounter in wanted:
						list.append(cols)
					listCounter += 1
				
				list[1] = list[1].replace("chr", "")

				try:
					query = "insert into dbo.{!s}".format(tablename) +\
						" values ( "

					for j in range(0, (len(list) - 1)):
						if j not in nonCharList:
							query += ("{!r}".format(list[j]) + ", ")
						else:
							query += (list[j] + ", ")	

					query += "{!r}".format(list[len(list) - 1])
					query += ");"

					cursor.execute(query)
					cursor.commit()

				# write errmsg if file I/O exception
				except Exception as eex:
					errorCounter += 1

					if errorCounter == 1:
						f = open("GC_{!r}_err.txt".format(tablename), "w")
						f.write(str(list) + "\n")
						print("ERROR in index " + str(index) + "!" )
					else:
						print("ERROR in index " + str(index) + "!" )
						f.write(str(list) + "\n")


				else:
					print("Insert " + str(index) + " was successful!")
	
	cursor.commit()
	print("File Read Done!" + str(fileName))
	cnxn.close()
						