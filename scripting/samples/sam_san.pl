
use perl_modules::regression;
use perl_modules::common;

execute(load_config("valar_test"));

$ssh = execute_ssh(login("192.168.1.207", "admin", "admin"));
$root_ssh = execute_ssh(login("192.168.1.207", "root", "testpass"));

my $result = "";
my $ftp_config_path = "ftp://valar:valar1\@3\@192.168.1.26/tmp/configs";

print_log($ANY, "====================== Regression Tests ======================");
print "====================== Regression Tests ======================\n";

print_log($ALL, "Config Backup");
$result = config_backup($ssh, $ftp_config_path);
print_log($ALL, $result);

print_log($ALL, "Show health");
$result = show_health($ssh, $root_ssh);
print_log($ALL, $result);

app_context($ssh);
policy_context($ssh);
global_context($ssh);
system_context($ssh);

show_all($ssh);

print_log($ALL, "Restore System Configurations");
config_restore($ssh, $ftp_config_path);
print_log($ALL, $result);

print_log($ALL, "Show health");
$result = show_health($ssh, $root_ssh);
print_log($ALL, $result);

$ssh->soft_close();
$root_ssh->soft_close();
