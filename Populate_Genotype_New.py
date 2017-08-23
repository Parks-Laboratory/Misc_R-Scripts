import pyodbc
import csv
import os
from functools import reduce
import argparse

# Create parser to receive instructions from command line
parser = argparse.ArgumentParser(description = 'Input arguments to populate database')
# Argument to create table and whether to create new table
parser.add_argument('-t', '--tablename', action = 'store', help = "Table for inserting data", default = "GENE_ANNOTATION")
parser.add_argument('-c', '--create', action = 'store_true', help = "Create table", default= False) 
# Argument to specify path
parser.add_argument('-p', '--path', action = 'store', help = "Directory path with txt file", default="E:/GENE_ANNOTATION")
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
			"geneStableID varchar(30)," \
			" transcriptStableID varchar(30)," \
			" geneStart int," \
			" geneEnd float," \
			" strand smallint," \
			" transcriptStart int," \
			" transcriptEnd char(40)," \
			" geneName varchar(20),"\
			" transcriptName varchar(30),"\
			" geneDescription varchar(max),"\
			" chromosomeName varchar(100),"\
			" transcriptionStartSite int,"\
			" transcriptLength smallint,"\
			" MGISymbol varchar(20),"\
			" NCBIGeneID varchar(15));"
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

			# Skip through the description header after the [Data] section 
			fileFormat = next(txtReader)

			index = 0
			# Resort each row to resemble the database format
			for rows in txtReader:

				index = index + 1

				list = []
				nonCharList = [2, 3, 4, 5, 11, 12]

				for cols in rows[0:]:

					list.append(cols)
				
				for i in range(0, len(list)):
					if list[i] == '':
						list[i] = 'NULL'

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
					print("ERROR!")

				else:
					print("Insert " + str(index) + " was successful!")
	
	cursor.commit()
	print("File Read Done!" + str(fileName))
	cnxn.close()
						