#!/usr/bin/perl -w
 
use DBI;
 
#print "Content-type: text/html\n\n";

## mysql user database name
$db ="valar";
## mysql database user name
$user = "test";
 
## mysql database password
$pass = "mysql";
 
## user hostname : This should be "localhost" but it can be diffrent too
$host="localhost";
 
$dbh = DBI->connect("DBI:mysql:$db:$host", $user, $pass);

print "********** My Perl DBI Test ***************\n";
print "Here is a list of tables in the MySQL database $db.\n";

## SQL query
$query = "show tables";
$sqlQuery  = $dbh->prepare($query) or die "Can't prepare $query: $dbh->errstr\n";
$sqlQuery->execute or die "can't execute the query: $sqlQuery->errstr";

@table_name = ();
while (@row= $sqlQuery->fetchrow_array()) 
{
	my $tables = $row[0];
	print "$tables\n";
	push @table_name, $tables;
}

print "\n Tables :\n" . join(", ", @table_name);
print "\n";
@table_name = ("detail");
foreach(@table_name)
{
	$query = "select * from $_";
	$sqlQuery  = $dbh->prepare($query) or die "Can't prepare $query: $dbh->errstr\n";
	$sqlQuery->execute or die "can't execute the query: $sqlQuery->errstr";
	 
	while (@row = $sqlQuery->fetchrow_array()) 
	{
		print join(", ", @row) . "\n";
	}
}
$rc = $sqlQuery->finish;
print "\n" . $rc . "\n";
exit(0);
