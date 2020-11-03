proc build_traftpcc { } {
global maxvuser suppo ntimes threadscreated _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict trafodion library ]} {
        set library [ dict get $dbdict trafodion library ]
} else { set library "tdbc::odbc" }
upvar #0 configtrafodion configtrafodion
#set variables to values in dict
setlocaltpccvars $configtrafodion
if { $trafodion_load_data eq "true" && $trafodion_build_jsps eq "true" } {
set trafmsg "Ready to create a $trafodion_count_ware Warehouse Trafodion TPROC-C schema\nin host [string toupper TCP:$trafodion_server:$trafodion_port] in schema $trafodion_schema with JSPs?"
	} else {
if { $trafodion_load_data eq "true" && $trafodion_build_jsps eq "false" } {
set trafmsg "Ready to create a $trafodion_count_ware Warehouse Trafodion TPROC-C schema\nin host [string toupper TCP:$trafodion_server:$trafodion_port] in schema $trafodion_schema without JSPs?"
	} else {
if { $trafodion_load_data eq "false" && $trafodion_build_jsps eq "true" } {
set trafmsg "Ready to create Trafodion JSPs only without data\nin host [string toupper TCP:$trafodion_server:$trafodion_port] in schema $trafodion_schema?"
		} else {
set trafmsg "No Trafodion Data to load or JSPs to create\nin host [string toupper TCP:$trafodion_server:$trafodion_port] in schema $trafodion_schema"
		}
	}
} 
if {[ tk_messageBox -title "Create Schema" -icon question -message $trafmsg -type yesno ] == yes} { 
if { $trafodion_num_vu eq 1 || $trafodion_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $trafodion_num_vu + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "Trafodion TPROC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#LOAD LIBRARIES AND MODULES
set library $library
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

proc finddirforstoredprocs {} {
        set result [ pwd ]       ;
        if {[file writable [ pwd ]]} {
            return [ pwd ]
        }
        if {[string match windows $::tcl_platform(platform)]} {
            if {[info exists env(TEMP)] && [file isdirectory $env(TEMP)] \
                    && [file writable $env(TEMP)]} {
                return $env(TEMP)
            }
            if {[info exists env(TMP)] && [file isdirectory $env(TMP)] \
                    && [file writable $env(TMP)]} {
                return $env(TMP)
            }
            if {[info exists env(TMPDIR)] && [file isdirectory $env(TMPDIR)] \
                    && [file writable $env(TMPDIR)]} {
                return $env(TMPDIR)
            }
            if {[file isdirectory C:/TEMP] && [file writable C:/TEMP]} {
                return C:/TEMP
            }
            if {[file isdirectory C:/] && [file writable C:/]} {
                return C:/
            }
        } else { ;
            if {[info exists env(TMP)] && [file isdirectory $env(TMP)] \
                    && [file writable $env(TMP)]} {
                return $env(TMP)
            }
            if {[info exists env(TMPDIR)] && [file isdirectory $env(TMPDIR)] \
                    && [file writable $env(TMPDIR)]} {
                return $env(TMPDIR)
            }
            if {[info exists env(TEMP)] && [file isdirectory $env(TEMP)] \
                    && [file writable $env(TEMP)]} {
                return $env(TEMP)
            }
            if {[file isdirectory /tmp] && [file writable /tmp]} {
                return /tmp
            }
 	}
        return "nodir"
	}

proc CreateStoredProcs { odbc schema nodelist copyremote } {
puts "CREATING TPCC STORED PROCEDURES"
set NEWORDER {import java.sql.*;
import java.math.*;
import java.util.Random;

public class NEWORDER {
public static int randInt(int min, int max) {
Random rand = new Random();
int randomNum = rand.nextInt((max - min) + 1) + min;
return randomNum;
}
public static void NEWORD (int no_w_id, int no_max_w_id, int no_d_id, int no_c_id, int no_o_ol_cnt, BigDecimal[] no_c_discount, String[] no_c_last, String[] no_c_credit, BigDecimal[] no_d_tax, BigDecimal[] no_w_tax, int[] no_d_next_o_id, Timestamp tstamp, ResultSet[] opres)   
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
BigDecimal no_o_all_local = new BigDecimal(0);
PreparedStatement getDiscTax =
conn.prepareStatement("SELECT c_discount, c_last, c_credit, w_tax " +
"FROM customer, warehouse " +
"WHERE warehouse.w_id = ? AND customer.c_w_id = ? AND " +
"customer.c_d_id = ? AND customer.c_id = ?");
getDiscTax.setInt(1, no_w_id);
getDiscTax.setInt(2, no_w_id);
getDiscTax.setInt(3, no_d_id);
getDiscTax.setInt(4, no_c_id);
ResultSet rs = getDiscTax.executeQuery();
rs.next();
no_c_discount[0] = rs.getBigDecimal(1);
no_c_last[0] = rs.getString(2);
no_c_credit[0] = rs.getString(3);
no_w_tax[0] = rs.getBigDecimal(4);
rs.close();
PreparedStatement getOidTax =
conn.prepareStatement("SELECT d_next_o_id, d_tax " +
"FROM district " +
"WHERE d_id = ? AND d_w_id = ? FOR UPDATE");
getOidTax.setInt(1, no_d_id);
getOidTax.setInt(2, no_w_id);
ResultSet rs1 = getOidTax.executeQuery();
rs1.next();
no_d_next_o_id[0] = rs1.getInt(1); 
no_d_tax[0] = rs1.getBigDecimal(2);
rs1.close();
PreparedStatement UpdDisc =
conn.prepareStatement("UPDATE district SET d_next_o_id = d_next_o_id + 1 " +
"WHERE d_id = ? AND d_w_id = ?");
UpdDisc.setInt(1, no_d_id);
UpdDisc.setInt(2, no_w_id);
UpdDisc.executeUpdate();
int o_id = no_d_next_o_id[0];
PreparedStatement InsOrd =
conn.prepareStatement("INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) " +
"VALUES (?, ?, ?, ?, ?, ?, ?)");
InsOrd.setInt(1, o_id);
InsOrd.setInt(2, no_d_id);
InsOrd.setInt(3, no_w_id);
InsOrd.setInt(4, no_c_id);
InsOrd.setTimestamp(5, tstamp);
InsOrd.setInt(6, no_o_ol_cnt);
InsOrd.setBigDecimal(7, no_o_all_local);
InsOrd.executeUpdate();
PreparedStatement InsNewOrd =
conn.prepareStatement("INSERT INTO new_order (no_o_id, no_d_id, no_w_id) " +
"VALUES (?, ?, ?)");
InsNewOrd.setInt(1, o_id);
InsNewOrd.setInt(2, no_d_id);
InsNewOrd.setInt(3, no_w_id);
InsNewOrd.executeUpdate();
int rbk = randInt(1,100);
int no_ol_i_id;
int no_ol_supply_w_id;
/* In Loop Statements Prepared Outside of Loop */
PreparedStatement SelNameData =
conn.prepareStatement("SELECT i_price, i_name, i_data FROM item " +
"WHERE i_id = ?");
PreparedStatement SelStock =
conn.prepareStatement("SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10 FROM stock " +
"WHERE s_i_id = ? AND s_w_id = ?");
PreparedStatement UpdStock =
conn.prepareStatement("UPDATE stock SET s_quantity = ? " +
"WHERE s_i_id = ? " +
"AND s_w_id = ?");
PreparedStatement InsLine =
conn.prepareStatement("INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info) " +
"VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
/* In Loop Statements Prepared Outside of Loop */
for (int loop_counter=1; loop_counter<=no_o_ol_cnt; loop_counter++) {
if ((loop_counter == no_o_ol_cnt) && (rbk == 1)) {
no_ol_i_id = 100001;
	}
	else {
no_ol_i_id = randInt(1,100000);
	}
int x = randInt(1,100);
if (x > 1) {
no_ol_supply_w_id = no_w_id;
	}
	else
	{
no_ol_supply_w_id = no_w_id;
//NOTE IN SPECIFICATION no_o_all_local set to 0 here but not needed
while ((no_ol_supply_w_id == no_w_id) && (no_max_w_id != 1)) {
no_ol_supply_w_id = randInt(1,no_max_w_id);
		}
	}
int no_ol_quantity = randInt(1,10);
SelNameData.setInt(1, no_ol_i_id);
ResultSet rs2 = SelNameData.executeQuery();
rs2.next();
BigDecimal no_i_price = rs2.getBigDecimal(1);
String no_i_name = rs2.getString(2);
String no_i_data = rs2.getString(3);
rs2.close();
SelStock.setInt(1, no_ol_i_id);
SelStock.setInt(2, no_ol_supply_w_id);
ResultSet rs3 = SelStock.executeQuery();
rs3.next();
int no_s_quantity = rs3.getInt(1);
String no_s_data = rs3.getString(2);
String no_s_dist_01 = rs3.getString(3);
String no_s_dist_02 = rs3.getString(4);
String no_s_dist_03 = rs3.getString(5);
String no_s_dist_04 = rs3.getString(6);
String no_s_dist_05 = rs3.getString(7);
String no_s_dist_06 = rs3.getString(8);
String no_s_dist_07 = rs3.getString(9);
String no_s_dist_08 = rs3.getString(10);
String no_s_dist_09 = rs3.getString(11);
String no_s_dist_10 = rs3.getString(12);
rs3.close();
if (no_s_quantity > no_ol_quantity) {
no_s_quantity = (no_s_quantity - no_ol_quantity);
	}
	else {
no_s_quantity = (no_s_quantity - no_ol_quantity + 91);
	}
UpdStock.setInt(1, no_s_quantity);
UpdStock.setInt(2, no_ol_i_id);
UpdStock.setInt(3, no_ol_supply_w_id);
UpdStock.executeUpdate();
BigDecimal onebd, disc, tax, no_ol_amount, quant, quant2;
onebd = new BigDecimal("1.0");
disc = onebd.subtract(no_c_discount[0]);
tax = onebd.add(no_w_tax[0].add(no_d_tax[0]));
quant = new BigDecimal(String.valueOf(no_ol_quantity));
quant2 = quant.multiply(no_i_price.multiply(tax.multiply(disc)));
no_ol_amount = quant2.setScale(2, RoundingMode.HALF_UP);
String no_ol_dist_info = "";
switch(no_d_id) {
case 1: no_ol_dist_info = no_s_dist_01;
	break;
case 2: no_ol_dist_info = no_s_dist_02;
	break;
case 3: no_ol_dist_info = no_s_dist_03;
	break;
case 4: no_ol_dist_info = no_s_dist_04;
	break;
case 5: no_ol_dist_info = no_s_dist_05;
	break;
case 6: no_ol_dist_info = no_s_dist_06;
	break;
case 7: no_ol_dist_info = no_s_dist_07;
	break;
case 8: no_ol_dist_info = no_s_dist_08;
	break;
case 9: no_ol_dist_info = no_s_dist_09;
	break;
case 10:no_ol_dist_info = no_s_dist_10;
	break;
	}
InsLine.setInt(1, o_id);
InsLine.setInt(2, no_d_id);
InsLine.setInt(3, no_w_id);
InsLine.setInt(4, loop_counter);
InsLine.setInt(5, no_ol_i_id);
InsLine.setInt(6, no_ol_supply_w_id);
InsLine.setInt(7, no_ol_quantity);
InsLine.setBigDecimal(8, no_ol_amount);
InsLine.setString(9, no_ol_dist_info);
InsLine.executeUpdate();
        }
conn.commit();
/* Return output parameters as a result set */
PreparedStatement getOutput =
conn.prepareStatement("SELECT ? AS NO_C_DISCOUNT,? AS NO_C_LAST,? AS NO_C_CREDIT,? AS NO_D_TAX,? AS NO_W_TAX,? AS NO_D_NEXT_O_ID from (values(1))x");
getOutput.setBigDecimal(1,no_c_discount[0]);
getOutput.setString(2,no_c_last[0]);
getOutput.setString(3,no_c_credit[0]);
getOutput.setBigDecimal(4,no_d_tax[0]);
getOutput.setBigDecimal(5,no_w_tax[0]);
getOutput.setInt(6,no_d_next_o_id[0]);
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set, database engine will close
conn.close();
*/
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
try {
conn.rollback();
    } catch (SQLException se2) {
se2.printStackTrace();
    }
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
}
set NEWORDER.proc "create procedure neworder(IN no_w_id INT, IN no_max_w_id INT, IN no_d_id INT, IN no_c_id INT, IN no_o_ol_cnt INT, OUT no_c_discount NUMERIC(4,4), OUT no_c_last VARCHAR(16), OUT no_c_credit CHAR(2), OUT no_d_tax NUMERIC(4,4), OUT no_w_tax NUMERIC(4,4), OUT no_d_next_o_id INT, IN tstamp TIMESTAMP) language java parameter style java reads sql data no transaction required external name \'NEWORDER.NEWORD\' library NEWORDER dynamic result sets 1"
set DELIVERY {import java.sql.*;
import java.math.*;
import java.io.*;
import java.util.*;

public class DELIVERY {
public static void DELIV (int d_w_id, int d_o_carrier_id, Timestamp tstamp)
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
int d_d_id;
/* In Loop Statements Prepared Outside of Loop */
PreparedStatement getNewOrd =
conn.prepareStatement("SELECT no_o_id FROM new_order " +
"WHERE no_w_id = ? " +
"AND no_d_id = ? " +
"ORDER BY no_o_id ASC LIMIT 1");
PreparedStatement delNewOrd =
conn.prepareStatement("DELETE FROM new_order " +
"WHERE no_w_id = ? " +
"AND no_d_id = ? " +
"AND no_o_id = ?");
PreparedStatement getCOrd =
conn.prepareStatement("SELECT o_c_id FROM orders " +
"WHERE o_id = ? " +
"AND o_d_id = ? " +
"AND o_w_id = ?");
PreparedStatement UpdOrd =
conn.prepareStatement("UPDATE orders SET o_carrier_id = ? " +
"WHERE o_id = ? " + 
"AND o_d_id = ? " +
"AND o_w_id = ?");
PreparedStatement UpdLine =
conn.prepareStatement("UPDATE order_line SET ol_delivery_d = ? " +
"WHERE ol_o_id = ? " +
"AND ol_d_id = ? " +
"AND ol_w_id = ?");
PreparedStatement getOrdAm =
conn.prepareStatement("SELECT SUM(ol_amount) " +
"FROM order_line " +
"WHERE ol_o_id = ? AND ol_d_id = ? " +
"AND ol_w_id = ?");
PreparedStatement UpdCust =
conn.prepareStatement("UPDATE customer SET c_balance = c_balance + ? " +
"WHERE c_id = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ?");
/* In Loop Statements Prepared Outside of Loop */
for (int loop_counter=1; loop_counter<=10; loop_counter++) {
d_d_id = loop_counter;
getNewOrd.setInt(1, d_w_id);
getNewOrd.setInt(2, d_d_id);
ResultSet rs = getNewOrd.executeQuery();
rs.next();
int d_no_o_id = rs.getInt(1);
rs.close();
delNewOrd.setInt(1, d_w_id);
delNewOrd.setInt(2, d_d_id);
delNewOrd.setInt(3, d_no_o_id);
delNewOrd.executeUpdate();
getCOrd.setInt(1, d_no_o_id);
getCOrd.setInt(2, d_d_id);
getCOrd.setInt(3, d_w_id);
ResultSet rs1 = getCOrd.executeQuery();
rs1.next();
int d_c_id = rs1.getInt(1);
rs1.close();
UpdOrd.setInt(1, d_o_carrier_id);
UpdOrd.setInt(2, d_no_o_id);
UpdOrd.setInt(3, d_d_id);
UpdOrd.setInt(4, d_w_id);
UpdOrd.executeUpdate();
UpdLine.setTimestamp(1, tstamp);
UpdLine.setInt(2, d_no_o_id); 
UpdLine.setInt(3, d_d_id); 
UpdLine.setInt(4, d_w_id); 
UpdLine.executeUpdate();
getOrdAm.setInt(1, d_no_o_id); 
getOrdAm.setInt(2, d_d_id); 
getOrdAm.setInt(3, d_w_id); 
ResultSet rs2 = getOrdAm.executeQuery();
rs2.next();
BigDecimal d_ol_total = rs2.getBigDecimal(1);
rs2.close();
UpdCust.setBigDecimal(1, d_ol_total);
UpdCust.setInt(2, d_d_id); 
UpdCust.setInt(3, d_d_id); 
UpdCust.setInt(4, d_w_id); 
UpdCust.executeUpdate();
System.out.println("D: " + d_d_id + "O: " + d_no_o_id + "time " + tstamp);
	}
/* No output parameters to return as a result set as uses print instead*/
conn.commit();
conn.close();
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
try {
conn.rollback();
    } catch (SQLException se2) {
se2.printStackTrace();
    }
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
} 
set DELIVERY.proc "create procedure delivery(IN d_w_id INT, IN d_o_carrier_id INT, IN tstamp TIMESTAMP) language java parameter style java reads sql data no transaction required external name \'DELIVERY.DELIV\' library DELIVERY"
set PAYMENT {import java.sql.*;
import java.math.*;

public class PAYMENT {
public static void PAY (int p_w_id, int p_d_id, int p_c_w_id, int p_c_d_id, int[] p_c_id, int byname, BigDecimal p_h_amount, String[] p_c_last, String[] p_w_street_1, String[] p_w_street_2, String[] p_w_city, String[] p_w_state, String[] p_w_zip, String[] p_d_street_1, String[] p_d_street_2, String[] p_d_city, String[] p_d_state, String[] p_d_zip, String[] p_c_first, String[] p_c_middle, String[] p_c_street_1, String[] p_c_street_2, String[] p_c_city, String[] p_c_state, String[] p_c_zip,  String[] p_c_phone, Timestamp[] p_c_since, String[] p_c_credit, BigDecimal[] p_c_credit_lim, BigDecimal[] p_c_discount, BigDecimal[] p_c_balance, String[] p_c_data, Timestamp tstamp, ResultSet[] opres)
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
PreparedStatement updWare =
conn.prepareStatement("UPDATE warehouse SET w_ytd = w_ytd + ? " +
"WHERE w_id = ?");
updWare.setBigDecimal(1, p_h_amount);
updWare.setInt(2, p_w_id); 
updWare.executeUpdate();
PreparedStatement selWare =
conn.prepareStatement("SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name " +
"FROM warehouse " +
"WHERE w_id = ?");
selWare.setInt(1, p_w_id); 
ResultSet rs = selWare.executeQuery();
rs.next();
p_w_street_1[0] = rs.getString(1);
p_w_street_2[0] = rs.getString(2);
p_w_city[0] = rs.getString(3);
p_w_state[0] = rs.getString(4);
p_w_zip[0] = rs.getString(5);
String p_w_name = rs.getString(6);
rs.close();
PreparedStatement updDisc =
conn.prepareStatement("UPDATE district SET d_ytd = d_ytd + ? " +
"WHERE d_w_id = ? AND d_id = ?");
updDisc.setBigDecimal(1, p_h_amount);
updDisc.setInt(2, p_w_id);
updDisc.setInt(3, p_d_id);
updDisc.executeUpdate();
PreparedStatement selDisc =
conn.prepareStatement("SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name " +
"FROM district " +
"WHERE d_w_id = ? AND d_id = ?");
selDisc.setInt(1, p_w_id); 
selDisc.setInt(2, p_d_id); 
ResultSet rs1 = selWare.executeQuery();
rs1.next();
p_d_street_1[0] = rs1.getString(1);
p_d_street_2[0] = rs1.getString(2);
p_d_city[0] = rs1.getString(3);
p_d_state[0] = rs1.getString(4);
p_d_zip[0] = rs1.getString(5);
String p_d_name = rs1.getString(6);
rs1.close();
if (byname == 1) {
PreparedStatement getCust =
conn.prepareStatement("SELECT count(c_id) " +
"FROM customer " +
"WHERE c_last = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ?");
getCust.setString(1, p_c_last[0]);
getCust.setInt(2, p_c_d_id);
getCust.setInt(3, p_c_w_id);
ResultSet rs2 = getCust.executeQuery();
rs2.next();
int namecnt = rs2.getInt(1);
rs2.close();
if ((namecnt % 2) == 1) {
namecnt = namecnt + 1;
	}
PreparedStatement CurCust =
conn.prepareStatement("SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since " +
"FROM customer " +
"WHERE c_w_id = ? " +
"AND c_d_id = ? " +
"AND c_last = ? " +
"ORDER BY c_first");
CurCust.setInt(1, p_c_w_id);
CurCust.setInt(2, p_c_d_id);
CurCust.setString(3, p_c_last[0]);
ResultSet rs3 = CurCust.executeQuery();
for (int loop_counter=0; loop_counter<=(namecnt / 2); loop_counter++) {
if(rs3.next()) {
p_c_first[0] = rs3.getString(1);
p_c_middle[0] = rs3.getString(2);
p_c_id[0] = rs3.getInt(3);
p_c_street_1[0] = rs3.getString(4);
p_c_street_2[0] = rs3.getString(5);
p_c_city[0] = rs3.getString(6);
p_c_state[0] = rs3.getString(7);
p_c_zip[0] = rs3.getString(8);
p_c_phone[0] = rs3.getString(9);
p_c_credit[0] = rs3.getString(10);
p_c_credit_lim[0] = rs3.getBigDecimal(11);
p_c_discount[0] = rs3.getBigDecimal(12);
p_c_balance[0] = rs3.getBigDecimal(13);
p_c_since[0] = rs3.getTimestamp(14);
		}
	}
rs3.close();
} else {
PreparedStatement IdCust =
conn.prepareStatement("SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since " +
"FROM customer " +
"WHERE c_w_id = ? " +
"AND c_d_id = ? " +
"AND c_id = ?");
IdCust.setInt(1, p_c_w_id);
IdCust.setInt(2, p_c_d_id);
IdCust.setInt(3, p_c_id[0]);
ResultSet rs4 = IdCust.executeQuery();
rs4.next();
p_c_first[0] = rs4.getString(1);
p_c_middle[0] = rs4.getString(2);
p_c_last[0] = rs4.getString(3);
p_c_street_1[0] = rs4.getString(4);
p_c_street_2[0] = rs4.getString(5);
p_c_city[0] = rs4.getString(6);
p_c_state[0] = rs4.getString(7);
p_c_zip[0] = rs4.getString(8);
p_c_phone[0] = rs4.getString(9);
p_c_credit[0] = rs4.getString(10);
p_c_credit_lim[0] = rs4.getBigDecimal(11);
p_c_discount[0] = rs4.getBigDecimal(12);
p_c_balance[0] = rs4.getBigDecimal(13);
p_c_since[0] = rs4.getTimestamp(14);
rs4.close();
}
p_c_balance[0] = p_c_balance[0].add(p_h_amount);
String badc = new String("BC");
if (p_c_credit[0].equals(badc)) {
PreparedStatement dataCust =
conn.prepareStatement("SELECT c_data " +
"FROM customer " +
"WHERE c_w_id = ? " +
"AND c_d_id = ? " +
"AND c_id = ?");
dataCust.setInt(1, p_c_w_id);
dataCust.setInt(2, p_c_d_id);
dataCust.setInt(3, p_c_id[0]);
ResultSet rs5 = dataCust.executeQuery();
rs5.next();
p_c_data[0] = rs5.getString(1);
String h_data = p_w_name + " " + p_d_name;
String p_c_new_data = p_c_id[0] + " " + p_c_d_id + " " + p_c_w_id + " " + p_d_id + " " + p_w_id + " " + String.format("%.2f",p_h_amount) + " " + tstamp + " " + h_data;
int new_data_len = p_c_new_data.length();
String tmp_new_data = p_c_new_data + "," + p_c_data[0];
if (tmp_new_data.length() <= 500) {
p_c_new_data = tmp_new_data;
	} else {
p_c_new_data = tmp_new_data.substring(1,500);
	}
PreparedStatement updBal =
conn.prepareStatement("UPDATE customer " +
"SET c_balance = ?, c_data = ? " +
"WHERE c_w_id = ? AND c_d_id = ? " +
"AND c_id = ?");
updBal.setBigDecimal(1, p_c_balance[0]);
updBal.setString(2, p_c_new_data);
updBal.setInt(3, p_c_w_id); 
updBal.setInt(4, p_c_d_id); 
updBal.setInt(5, p_c_id[0]); 
updBal.executeUpdate();
	} else {
p_c_data[0] = "NO P_C_DATA FOR GOOD CREDIT";
PreparedStatement updBal2 =
conn.prepareStatement("UPDATE customer " +
"SET c_balance = ? " +
"WHERE c_w_id = ? AND c_d_id = ? " +
"AND c_id = ?");
updBal2.setBigDecimal(1, p_c_balance[0]);
updBal2.setInt(2, p_c_w_id); 
updBal2.setInt(3, p_c_d_id); 
updBal2.setInt(4, p_c_id[0]); 
updBal2.executeUpdate();
	}
String h_data = p_w_name + " " + p_d_name;
PreparedStatement insHist =
conn.prepareStatement("INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) " +
"VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
insHist.setInt(1, p_c_d_id); 
insHist.setInt(2, p_c_w_id); 
insHist.setInt(3, p_c_id[0]); 
insHist.setInt(4, p_d_id); 
insHist.setInt(5, p_w_id); 
insHist.setTimestamp(6, tstamp);
insHist.setBigDecimal(7, p_h_amount);
insHist.setString(8, h_data);
insHist.executeUpdate();
if (p_c_data[0].length() <= 255) {
	;
	} else {
p_c_data[0] = p_c_data[0].substring(1,255);
	}
conn.commit();
PreparedStatement getOutput =
conn.prepareStatement("SELECT ? AS P_C_ID,? AS P_C_LAST,? AS P_W_STREET_1,? AS P_W_STREET_2,? AS P_W_CITY,? AS P_W_STATE,? AS P_W_ZIP,? AS P_D_STREET_1,? AS P_D_STREET_2,? AS P_D_CITY,? AS P_D_STATE,? AS P_D_ZIP,? AS P_C_FIRST,? AS P_C_MIDDLE,? AS P_C_STREET_1,? AS P_C_STREET_2, ? AS P_C_CITY,? AS P_C_STATE,? AS P_C_ZIP,? AS P_C_PHONE,? AS P_C_SINCE,? AS P_C_CREDIT,? AS P_C_CREDIT_LIM,? AS P_C_DISCOUNT,? AS P_C_BALANCE,? AS P_C_DATA from (values(1))x");
getOutput.setInt(1, p_c_id[0]);
getOutput.setString(2, p_c_last[0]);
getOutput.setString(3, p_w_street_1[0]);
getOutput.setString(4, p_w_street_2[0]);
getOutput.setString(5, p_w_city[0]);
getOutput.setString(6, p_w_state[0]);
getOutput.setString(7, p_w_zip[0]);
getOutput.setString(8, p_d_street_1[0]);
getOutput.setString(9, p_d_street_2[0]);
getOutput.setString(10,  p_d_city[0]);
getOutput.setString(11, p_d_state[0]);
getOutput.setString(12, p_d_zip[0]);
getOutput.setString(13, p_c_first[0]);
getOutput.setString(14, p_c_middle[0]);
getOutput.setString(15, p_c_street_1[0]);
getOutput.setString(16, p_c_street_2[0]);
getOutput.setString(17, p_c_city[0]);
getOutput.setString(18, p_c_state[0]);
getOutput.setString(19, p_c_zip[0]);
getOutput.setString(20, p_c_phone[0]);
getOutput.setTimestamp(21, p_c_since[0]);
getOutput.setString(22, p_c_credit[0]);
getOutput.setBigDecimal(23, p_c_credit_lim[0]);
getOutput.setBigDecimal(24, p_c_discount[0]);
getOutput.setBigDecimal(25, p_c_balance[0]);
getOutput.setString(26, p_c_data[0]);
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set, database engine will close
conn.close();
*/
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
try {
conn.rollback();
    } catch (SQLException se2) {
se2.printStackTrace();
    }
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
}
set PAYMENT.proc "create procedure payment(IN p_w_id INT, IN p_d_id INT, IN p_c_w_id INT, IN p_c_d_id INT, INOUT p_c_id INT, IN byname INT, IN p_h_amount NUMERIC(6,2), INOUT p_c_last VARCHAR(16), OUT p_w_street_1 VARCHAR(20), OUT p_w_street_2 VARCHAR(20), OUT p_w_city VARCHAR(20), OUT p_w_state CHAR(2), OUT p_w_zip CHAR(9), OUT p_d_street_1 VARCHAR(20), OUT p_d_street_2 VARCHAR(20), OUT p_d_city VARCHAR(20), OUT p_d_state CHAR(2), OUT p_d_zip CHAR(9), OUT p_c_first VARCHAR(16), OUT p_c_middle CHAR(2), OUT p_c_street_1 VARCHAR(20), OUT p_c_street_2 VARCHAR(20), OUT p_c_city VARCHAR(20), OUT p_c_state CHAR(2), OUT p_c_zip CHAR(9), OUT p_c_phone CHAR(16), OUT p_c_since TIMESTAMP, INOUT p_c_credit CHAR(2), OUT p_c_credit_lim NUMERIC(12,2), OUT p_c_discount NUMERIC(4,4), INOUT p_c_balance NUMERIC(12,2), OUT p_c_data VARCHAR(500), IN tstamp TIMESTAMP) language java parameter style java reads sql data no transaction required external name \'PAYMENT.PAY\' library PAYMENT dynamic result sets 1"
set ORDERSTATUS {import java.sql.*;
import java.math.*;

public class ORDERSTATUS {
public static void OSTAT (int os_w_id, int os_d_id, int[] os_c_id, int byname, String[] os_c_last, String[] os_c_first, String[] os_c_middle, BigDecimal[] os_c_balance, int[] os_o_id, Timestamp[] os_entdate, int[] os_o_carrier_id, ResultSet[] opres)
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
if (byname == 1) {
PreparedStatement getCust =
conn.prepareStatement("SELECT count(c_id) " +
"FROM customer " +
"WHERE c_last = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ?");
getCust.setString(1, os_c_last[0]);
getCust.setInt(2, os_d_id);
getCust.setInt(3, os_w_id);
ResultSet rs = getCust.executeQuery();
rs.next();
int namecnt = rs.getInt(1);
rs.close();
if ((namecnt % 2) == 1) {
namecnt = namecnt + 1;
	}
PreparedStatement CurCust =
conn.prepareStatement("SELECT c_balance, c_first, c_middle, c_id " +
"FROM customer " +
"WHERE c_last = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ? " +
"ORDER BY c_first");
CurCust.setString(1, os_c_last[0]);
CurCust.setInt(2, os_d_id);
CurCust.setInt(3, os_w_id);
ResultSet rs1 = CurCust.executeQuery();
for (int loop_counter=0; loop_counter<=(namecnt / 2); loop_counter++) {
if(rs1.next()) {
os_c_balance[0] = rs1.getBigDecimal(1);
os_c_first[0] = rs1.getString(2);
os_c_middle[0] = rs1.getString(3);
os_c_id[0] = rs1.getInt(4);
		}
	}
rs1.close();
} else {
PreparedStatement IdCust =
conn.prepareStatement("SELECT c_balance, c_first, c_middle, c_last " +
"FROM customer " +
"WHERE c_id = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ?");
IdCust.setInt(1, os_c_id[0]);
IdCust.setInt(2, os_d_id);
IdCust.setInt(3, os_w_id);
ResultSet rs2 = IdCust.executeQuery();
rs2.next();
os_c_balance[0] = rs2.getBigDecimal(1);
os_c_first[0] = rs2.getString(2);
os_c_middle[0] = rs2.getString(3);
os_c_last[0] = rs2.getString(4);
rs2.close();
}
PreparedStatement SubOrd =
conn.prepareStatement("SELECT o_id, o_carrier_id, o_entry_d " +
"FROM orders where o_d_id = ? AND o_w_id = ? and o_c_id = ? " +
"ORDER BY o_id DESC LIMIT 1");
SubOrd.setInt(1, os_d_id);
SubOrd.setInt(2, os_w_id);
SubOrd.setInt(3, os_c_id[0]);
ResultSet rs3 = SubOrd.executeQuery();
if (rs3.next()) {
os_o_id[0] = rs3.getInt(1);
os_o_carrier_id[0] = rs3.getInt(2);
os_entdate[0] = rs3.getTimestamp(3);
	} else {
System.out.println("No Orders for Customer");
rs3.close();
PreparedStatement getOutput =
conn.prepareStatement("select 'no orders for customer' as NOORD from (values(1))x");
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set
conn.close();
*/
return;
	}
PreparedStatement CLine =
conn.prepareStatement("SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d " +
"FROM order_line " +
"WHERE ol_o_id = ? AND ol_d_id = ? AND ol_w_id = ?");
CLine.setInt(1, os_o_id[0]);
CLine.setInt(2, os_d_id);
CLine.setInt(3, os_w_id);
ResultSet rs4 = CLine.executeQuery();
int i=0;
int[] os_ol_i_id = new int[15];
int[] os_ol_supply_w_id = new int[15];
int[] os_ol_quantity  = new int[15];
int[] os_ol_amount = new int[15];
Timestamp [] os_ol_delivery_d = new Timestamp[15];
while (rs4.next()) {
os_ol_i_id[i] = rs4.getInt(1);
os_ol_supply_w_id[i] = rs4.getInt(2);
os_ol_quantity[i] = rs4.getInt(3);
os_ol_amount[i] = rs4.getInt(4);
os_ol_delivery_d[i] = rs4.getTimestamp(5);
i++;
	}
rs4.close();
/* Return output parameters as a result set */
PreparedStatement getOutput =
conn.prepareStatement("SELECT ? AS OS_C_ID,? AS OS_C_LAST,? AS OS_C_FIRST,? AS OS_C_MIDDLE,? AS OS_C_BALANCE,? AS OS_O_ID,? AS OS_ENTDATE,? AS OS_O_CARRIER_ID from (values(1))x");
getOutput.setInt(1, os_c_id[0]);
getOutput.setString(2, os_c_last[0]);
getOutput.setString(3, os_c_first[0]);
getOutput.setString(4, os_c_middle[0]);
getOutput.setBigDecimal(5, os_c_balance[0]);
getOutput.setInt(6, os_o_id[0]);
getOutput.setTimestamp(7, os_entdate[0]);
getOutput.setInt(8, os_o_carrier_id[0]);
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set, database engine will close
conn.close();
*/
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
}
set ORDERSTATUS.proc "create procedure orderstatus(IN os_w_id INT, IN os_d_id INT, INOUT os_c_id INT, IN byname INT, INOUT os_c_last VARCHAR(16), OUT os_c_first VARCHAR(16), OUT os_c_middle CHAR(2), OUT os_c_balance NUMERIC(12,2), OUT os_o_id INT, OUT os_entdate TIMESTAMP, OUT os_o_carrier_id INT) language java parameter style java reads sql data no transaction required external name \'ORDERSTATUS.OSTAT\' library ORDERSTATUS dynamic result sets 1"
set STOCKLEVEL {import java.sql.*;

public class STOCKLEVEL {
public static void SLEV (int st_w_id, int st_d_id, int threshold, int[] st_o_id, int[] stock_count, ResultSet[] opres)
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
PreparedStatement getNextOid =
conn.prepareStatement("SELECT d_next_o_id " +
"FROM district " +
"WHERE d_w_id = ? and d_id = ?");
getNextOid.setInt(1, st_w_id);
getNextOid.setInt(2, st_d_id);
ResultSet rs = getNextOid.executeQuery();
rs.next();
st_o_id[0] = rs.getInt(1);
rs.close();
PreparedStatement getStockCount =
conn.prepareStatement("SELECT COUNT(DISTINCT (STOCK.s_i_id)) " +
"FROM order_line, stock " +
"WHERE ORDER_LINE.ol_w_id = ? " +
"AND ORDER_LINE.ol_d_id = ? " +
"AND (ORDER_LINE.ol_o_id < ?) " +
"AND ORDER_LINE.ol_o_id >= (? - 20) " +
"AND STOCK.s_w_id = ? " + 
"AND STOCK.s_i_id = ORDER_LINE.ol_i_id " +
"AND STOCK.s_quantity < ?");
getStockCount.setInt(1, st_w_id);
getStockCount.setInt(2, st_d_id);
getStockCount.setInt(3, st_o_id[0]);
getStockCount.setInt(4, st_o_id[0]);
getStockCount.setInt(5, st_w_id);
getStockCount.setInt(6, threshold);
ResultSet rs2 = getStockCount.executeQuery();
rs2.next();
stock_count[0] = rs2.getInt(1);
rs2.close();
/* Return output parameters as a result set */
PreparedStatement getOutput =
conn.prepareStatement("SELECT ? AS ST_O_ID,? AS STOCK_COUNT from (values(1))x");
getOutput.setInt(1, st_o_id[0]);
getOutput.setInt(2, stock_count[0]);
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set, database engine will close
conn.close();
*/
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
}
set STOCKLEVEL.proc "create procedure stocklevel(IN st_w_id INT, IN st_d_id INT, IN threshold INT, OUT st_o_id INT, OUT stock_count INT) language java parameter style java reads sql data no transaction required external name \'STOCKLEVEL.SLEV\' library STOCKLEVEL dynamic result sets 1"
set present [ pwd ]
set dir [ finddirforstoredprocs ]
if { $dir eq "nodir" } {
error "No directory found to create stored procedures"
return
	} else {
if { $present eq $dir } {
	;
	} else {
cd $dir
	}
foreach java {NEWORDER DELIVERY PAYMENT ORDERSTATUS STOCKLEVEL} {
set data [ set $java ]
set filename $java.java
set classfile $java.class
set jarfile [ file join $dir $java.jar ]
set sqllib "create library $java file \'$jarfile\'"
set sqlproc [ set $java.proc ]
set fileId [ open $filename "w"]
puts -nonewline $fileId $data
close $fileId
eval exec [auto_execok javac] $filename
eval exec [auto_execok jar] [ list cvf $jarfile $classfile ]
if [ catch {set stmnt [ odbc prepare $sqllib ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to create library $jarfile"
error $message
} else {
$rs close
$stmnt close
     }
    }
if [ catch {set stmnt [ odbc prepare $sqlproc ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
puts -nonewline "Creating $java"
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to create procedure $java"
error $message
} else {
$rs close
$stmnt close
     }
    }
if { $copyremote } {
puts -nonewline "Copying $jarfile to $nodelist using pdcp"
catch { exec pdcp } msg
if { [ string match "*pcp requires source and dest filenames" $msg ] } {
eval exec [ auto_execok pdcp ] [ list -w [ list $nodelist ] $jarfile $jarfile ]
	} else {
error "command pdcp does not exist, install the pdsh package to copy remote"
	}
    } else {
puts "Library on local node only"
}
catch {file delete -force $filename}
catch {file delete -force $classfile}
   }
if { $present eq $dir } {
	;
	} else {
cd $present
	}
  }
return
}

proc UpdateStatistics { odbc schema } {
puts "UPDATING SCHEMA STATISTICS"
set sql(1) "set schema trafodion.$schema"
set sql(2) "update statistics for table CUSTOMER on every column sample"
set sql(3) "update statistics for table DISTRICT on every column sample"
set sql(4) "update statistics for table HISTORY on every column sample"
set sql(5) "update statistics for table ITEM on every column sample"
set sql(6) "update statistics for table WAREHOUSE on every column sample"
set sql(7) "update statistics for table STOCK on every column sample"
set sql(8) "update statistics for table NEW_ORDER on every column sample"
set sql(9) "update statistics for table ORDERS on every column sample"
set sql(10) "update statistics for table ORDER_LINE on every column sample"
for { set i 1 } { $i <= 10 } { incr i } {
if [ catch {set stmnt [ odbc prepare $sql($i) ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
puts -nonewline "$i..."
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Update Statistics"
error $message
} else {
$rs close
$stmnt close
     }
  }
}
return
}

proc CreateSchema { odbc schema } {
if [ catch {set stmnt [ odbc prepare "create schema trafodion.$schema" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Create Schema trafodion.$schema"
error $message
} else {
$rs close
$stmnt close
    }
 }
return
}

proc SetSchema { odbc schema } {
if [ catch {set stmnt [ odbc prepare "set schema trafodion.$schema" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Set Schema trafodion.$schema"
error $message
} else {
$rs close
$stmnt close
    }
 }
return
}

proc CreateTables { odbc schema } {
puts "CREATING TPCC TABLES"
set sql(1) "set schema trafodion.$schema"
set sql(2) "CREATE TABLE CUSTOMER (C_ID NUMERIC(5,0) NOT NULL NOT DROPPABLE, C_D_ID NUMERIC(2,0) NOT NULL NOT DROPPABLE, C_W_ID NUMERIC(4,0) NOT NULL NOT DROPPABLE, C_FIRST VARCHAR(16), C_MIDDLE CHAR(2), C_LAST VARCHAR(16), C_STREET_1 VARCHAR(20), C_STREET_2 VARCHAR(20), C_CITY VARCHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE TIMESTAMP, C_CREDIT CHAR(2), C_CREDIT_LIM NUMERIC(12, 2), C_DISCOUNT NUMERIC(4,4), C_BALANCE NUMERIC(12, 2), C_YTD_PAYMENT NUMERIC(12, 2), C_PAYMENT_CNT NUMERIC(8,0), C_DELIVERY_CNT NUMERIC(8,0), C_DATA VARCHAR(500), PRIMARY KEY (C_W_ID, C_D_ID, C_ID))"
set sql(3) "CREATE TABLE DISTRICT (D_ID NUMERIC(2,0) NOT NULL NOT DROPPABLE, D_W_ID NUMERIC(4,0) NOT NULL NOT DROPPABLE, D_YTD NUMERIC(12, 2), D_TAX NUMERIC(4,4), D_NEXT_O_ID NUMERIC, D_NAME VARCHAR(10), D_STREET_1 VARCHAR(20), D_STREET_2 VARCHAR(20), D_CITY VARCHAR(20), D_STATE CHAR(2), D_ZIP CHAR(9), PRIMARY KEY (D_W_ID, D_ID))"
set sql(4) "CREATE TABLE HISTORY (H_C_ID NUMERIC, H_C_D_ID NUMERIC, H_C_W_ID NUMERIC, H_D_ID NUMERIC, H_W_ID NUMERIC, H_DATE TIMESTAMP, H_AMOUNT NUMERIC(6,2), H_DATA VARCHAR(24))"
set sql(5) "CREATE TABLE ITEM (I_ID NUMERIC(6,0) NOT NULL NOT DROPPABLE, I_IM_ID NUMERIC, I_NAME VARCHAR(24), I_PRICE NUMERIC(5,2), I_DATA VARCHAR(50), PRIMARY KEY (I_ID))"
set sql(6) "CREATE TABLE WAREHOUSE (W_ID NUMERIC(4,0) NOT NULL NOT DROPPABLE, W_YTD NUMERIC(12, 2), W_TAX NUMERIC(4,4), W_NAME VARCHAR(10), W_STREET_1 VARCHAR(20), W_STREET_2 VARCHAR(20), W_CITY VARCHAR(20), W_STATE CHAR(2), W_ZIP CHAR(9), PRIMARY KEY (W_ID))"
set sql(7) "CREATE TABLE STOCK (S_I_ID NUMERIC(6,0) NOT NULL NOT DROPPABLE, S_W_ID NUMERIC(4,0) NOT NULL NOT DROPPABLE, S_QUANTITY NUMERIC(6,0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMERIC(10, 0), S_ORDER_CNT NUMERIC(6,0), S_REMOTE_CNT NUMERIC(6,0), S_DATA VARCHAR(50), PRIMARY KEY (S_W_ID, S_I_ID))"
set sql(8) "CREATE TABLE NEW_ORDER (NO_W_ID NUMERIC NOT NULL NOT DROPPABLE, NO_D_ID NUMERIC NOT NULL NOT DROPPABLE, NO_O_ID NUMERIC NOT NULL NOT DROPPABLE, PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID))"
set sql(9) "CREATE TABLE ORDERS (O_ID NUMERIC NOT NULL NOT DROPPABLE, O_W_ID NUMERIC NOT NULL NOT DROPPABLE, O_D_ID NUMERIC NOT NULL NOT DROPPABLE, O_C_ID NUMERIC, O_CARRIER_ID NUMERIC DEFAULT NULL, O_OL_CNT NUMERIC, O_ALL_LOCAL NUMERIC, O_ENTRY_D TIMESTAMP, PRIMARY KEY (O_W_ID, O_D_ID, O_ID))"
set sql(10) "CREATE TABLE ORDER_LINE (OL_W_ID NUMERIC NOT NULL NOT DROPPABLE, OL_D_ID NUMERIC NOT NULL NOT DROPPABLE, OL_O_ID NUMERIC NOT NULL NOT DROPPABLE, OL_NUMBER NUMERIC NOT NULL NOT DROPPABLE, OL_I_ID NUMERIC, OL_DELIVERY_D TIMESTAMP, OL_AMOUNT NUMERIC(6,2), OL_SUPPLY_W_ID NUMERIC, OL_QUANTITY NUMERIC, OL_DIST_INFO CHAR(24), PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER))"
for { set i 1 } { $i <= 10 } { incr i } {
if [ catch {set stmnt [ odbc prepare $sql($i) ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Create Table"
error $message
} else {
$rs close
$stmnt close
     }
  }
}
return
}

proc CreateIndexes { odbc schema } {
puts "CREATING TPCC INDEXES"
set sql(1) "set schema trafodion.$schema"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER (C_W_ID, C_D_ID, C_LAST, C_FIRST, C_ID)"
set sql(3) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
for { set i 1 } { $i <= 3 } { incr i } {
if { $i eq 2 } {
puts "Creating Index CUSTOMER_I2..."
	}
if { $i eq 3 } {
puts "Creating Index ORDERS_I2..."
	}
if [ catch {set stmnt [ odbc prepare $sql($i) ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Create Index"
error $message
} else {
$rs close
$stmnt close
     }
  }
}
return
}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
return $tstamp
}

proc SetLoadString { loadtype } {
if { $loadtype eq "upsert" } { 
	set insupsert "upsert using load" 
	} else {
	set insupsert "insert" 
	}
return $insupsert
}

proc MakeValueBinds { values count } {
set len [ llength [ tdbc::tokenize $values ]] 
set TokLst "VALUES ("
for {set i 1} {$i <= $count } {incr i } {
set tokcnt 1
foreach token [ tdbc::tokenize $values ] {
append TokLst $token "_" $i
if { $tokcnt < $len } { append TokLst ", "}
incr tokcnt
	}
if { $i < $count } { append TokLst "),(" }
}
append TokLst ")"
return $TokLst
}

proc Customer { odbc d_id w_id CUST_PER_DIST loadtype } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set bld_cnt 1
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
set insupsert [ SetLoadString $loadtype ]
if [ catch {set stmnt_cust [ odbc prepare "$insupsert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) [ MakeValueBinds {:c_id:c_d_id:c_w_id:c_first:c_middle:c_last:c_street_1:c_street_2:c_city:c_state:c_zip:c_phone:c_since:c_credit:c_credit_lim:c_discount:c_balance:c_data:c_ytd_payment:c_payment_cnt:c_delivery_cnt} 100 ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        } 
if [ catch {set stmnt_hist [ odbc prepare "$insupsert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) [ MakeValueBinds {:h_c_id:h_c_d_id:h_c_w_id:h_w_id:h_d_id:h_date:h_amount:h_data} 100 ]"]} message ] {
puts "Failed to prepare statement"
error $message
        } 
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
lappend valdict_cust c_id_$bld_cnt $c_id c_d_id_$bld_cnt $c_d_id c_w_id_$bld_cnt $c_w_id c_first_$bld_cnt $c_first c_middle_$bld_cnt $c_middle c_last_$bld_cnt $c_last c_street_1_$bld_cnt [ lindex $c_add 0 ] c_street_2_$bld_cnt [ lindex $c_add 1 ] c_city_$bld_cnt [ lindex $c_add 2 ] c_state_$bld_cnt [ lindex $c_add 3 ] c_zip_$bld_cnt [ lindex $c_add 4 ] c_phone_$bld_cnt $c_phone c_since_$bld_cnt [ gettimestamp ] c_credit_$bld_cnt $c_credit c_credit_lim_$bld_cnt $c_credit_lim c_discount_$bld_cnt $c_discount c_balance_$bld_cnt $c_balance c_data_$bld_cnt $c_data c_ytd_payment_$bld_cnt 10.0 c_payment_cnt_$bld_cnt 1 c_delivery_cnt_$bld_cnt 0
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
lappend valdict_hist h_c_id_$bld_cnt $c_id h_c_d_id_$bld_cnt $c_d_id h_c_w_id_$bld_cnt $c_w_id h_w_id_$bld_cnt $c_w_id h_d_id_$bld_cnt $c_d_id h_date_$bld_cnt [ gettimestamp ] h_amount_$bld_cnt $h_amount h_data_$bld_cnt $h_data
incr bld_cnt
if { ![ expr {$c_id % 100} ] } {
if [catch {set rs_1 [ $stmnt_cust execute $valdict_cust ]} message ] {
puts "Failed to execute statement"
error $message
	} else {
	$rs_1 close
        }
if [catch {set rs_2 [ $stmnt_hist execute $valdict_hist ]} message ] {
puts "Failed to execute statement"
error $message
	} else {
	$rs_2 close
        }
	set bld_cnt 1
	unset valdict_cust
	unset valdict_hist
	}
       }
$stmnt_cust close
$stmnt_hist close
puts "Customer Done"
return
}

proc Orders { odbc d_id w_id MAXITEMS ORD_PER_DIST loadtype} {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Orders for D=$d_id W=$w_id"
set insupsert [ SetLoadString $loadtype ]
if [ catch {set stmnt_ord [ odbc prepare "$insupsert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) [ MakeValueBinds {:o_id:o_c_id:o_d_id:o_w_id:o_entry_d:o_carrier_id:o_ol_cnt:o_all_local} 100 ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        }
if [ catch {set stmnt_new_ord [ odbc prepare "$insupsert into new_order (no_o_id, no_d_id, no_w_id) [ MakeValueBinds {:no_o_id:no_d_id:no_w_id} 100 ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        } 
for {set olc 5} {$olc <= 15 } {incr olc } {
if [ catch {set stmnt_ord_lin_$olc [ odbc prepare "$insupsert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) [ MakeValueBinds {:ol_o_id:ol_d_id:ol_w_id:ol_number:ol_i_id:ol_supply_w_id:ol_quantity:ol_amount:ol_dist_info:ol_delivery_d} $olc ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        } 
 }
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
#Note o_carrier_id is null so omitted below 
lappend valdict_ord o_id_$bld_cnt $o_id o_c_id_$bld_cnt $o_c_id o_d_id_$bld_cnt $o_d_id o_w_id_$bld_cnt $o_w_id o_entry_d_$bld_cnt [ gettimestamp ] o_ol_cnt_$bld_cnt $o_ol_cnt o_all_local_$bld_cnt 1
set e "no1"
lappend valdict_new_ord no_o_id_$bld_cnt $o_id no_d_id_$bld_cnt $o_d_id no_w_id_$bld_cnt $o_w_id
  } else {
  set e "o3"
lappend valdict_ord o_id_$bld_cnt $o_id o_c_id_$bld_cnt $o_c_id o_d_id_$bld_cnt $o_d_id o_w_id_$bld_cnt $o_w_id o_entry_d_$bld_cnt [gettimestamp ] o_carrier_id_$bld_cnt $o_carrier_id o_ol_cnt_$bld_cnt $o_ol_cnt o_all_local_$bld_cnt 1
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 00.00
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
#Note ol_delivery_d is null so omitted below
lappend valdict_line ol_o_id_$ol $o_id ol_d_id_$ol $o_d_id ol_w_id_$ol $o_w_id ol_number_$ol $ol ol_i_id_$ol $ol_i_id ol_supply_w_id_$ol $ol_supply_w_id ol_quantity_$ol $ol_quantity ol_amount_$ol $ol_amount ol_dist_info_$ol $ol_dist_info
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.00} ]
set e "ol2"
lappend valdict_line ol_o_id_$ol $o_id ol_d_id_$ol $o_d_id ol_w_id_$ol $o_w_id ol_number_$ol $ol ol_i_id_$ol $ol_i_id ol_supply_w_id_$ol $ol_supply_w_id ol_quantity_$ol $ol_quantity ol_amount_$ol $ol_amount ol_dist_info_$ol $ol_dist_info ol_delivery_d_$ol [ gettimestamp ]
	}
}
set stmnt stmnt_ord_lin_$o_ol_cnt
if [catch {set rs_3 [ [ set $stmnt ] execute $valdict_line ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs_3 close
	unset valdict_line
       }
incr bld_cnt
 if { ![ expr {$o_id % 100} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
if [catch {set rs_1 [ $stmnt_ord execute $valdict_ord ]} message ] {
puts "Failed to execute statement"
error $message
	} else {
        $rs_1 close
        }
if { $o_id > 2100 } {
if [catch {set rs_2 [ $stmnt_new_ord execute $valdict_new_ord ]} message ] {
puts "Failed to execute statement"
error $message
} else {
       $rs_2 close
       }
      }
	set bld_cnt 1
	unset valdict_ord
	unset -nocomplain valdict_new_ord
			}
		}
	$stmnt_ord close
	$stmnt_new_ord close
	for {set olc 5} {$olc <= 15 } {incr olc } {
	set stmnt stmnt_ord_lin_$olc
	[ set $stmnt ] close
	}
	puts "Orders Done"
	return
}

proc OrdersforWindows { odbc d_id w_id MAXITEMS ORD_PER_DIST loadtype} {
#High performance Linux build fails on Windows
#Orders procedure duplicated in anticipation of being dropped when Linux proc above works on Windows
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Orders for D=$d_id W=$w_id"
set insupsert [ SetLoadString $loadtype ]
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
append o_val_list ($o_id, $o_c_id, $o_d_id, $o_w_id, CURRENT, null, $o_ol_cnt, 1)
set e "no1"
append no_val_list ($o_id, $o_d_id, $o_w_id)
  } else {
  set e "o3"
append o_val_list ($o_id, $o_c_id, $o_d_id, $o_w_id, CURRENT, $o_carrier_id, $o_ol_cnt, 1)
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 00.00
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ($o_id, $o_d_id, $o_w_id, $ol, $ol_i_id, $ol_supply_w_id, $ol_quantity, $ol_amount, '$ol_dist_info', null)
if { $bld_cnt<= 49 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.00} ]
set e "ol2"
append ol_val_list ($o_id, $o_d_id, $o_w_id, $ol, $ol_i_id, $ol_supply_w_id, $ol_quantity, $ol_amount, '$ol_dist_info', CURRENT)
if { $bld_cnt<= 49 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 49 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 50} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
if [ catch {set stmnt [ odbc prepare "$insupsert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
      }
if { $o_id > 2100 } {
if [ catch {set stmnt [ odbc prepare "$insupsert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
      }
     }
if [ catch {set stmnt [ odbc prepare "$insupsert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
      }
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	puts "Orders Done"
	return
}

proc LoadItems { odbc MAXITEMS loadtype } {
puts "Start:[ clock format [ clock seconds ] ]"
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Item"
set insupsert [ SetLoadString $loadtype ]
if [ catch {set stmnt [ odbc prepare "$insupsert into item (i_id, i_im_id, i_name, i_price, i_data) [ MakeValueBinds {:i_id:i_im_id:i_name:i_price:i_data} 100 ]" ]} message ] {
puts "Failed to prepare item statement"
error $message
        } 
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
lappend valdict i_id_$bld_cnt $i_id i_im_id_$bld_cnt $i_im_id i_name_$bld_cnt $i_name i_price_$bld_cnt $i_price i_data_$bld_cnt $i_data
incr bld_cnt
 if { ![ expr {$i_id % 100} ] } {
if [catch {set rs [ $stmnt execute $valdict ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
       }
	set bld_cnt 1
        unset valdict
	}
      if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
			}
		}
	$stmnt close
	puts "Item done"
	return
	}

proc Stock { odbc w_id MAXITEMS loadtype } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Stock Wid=$w_id"
set insupsert [ SetLoadString $loadtype ]
if [ catch {set stmnt [ odbc prepare "$insupsert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt)[ MakeValueBinds {:s_i_id:s_w_id:s_quantity:s_dist_01:s_dist_02:s_dist_03:s_dist_04:s_dist_05:s_dist_06:s_dist_07:s_dist_08:s_dist_09:s_dist_10:s_data:s_ytd:s_order_cnt:s_remote_cnt} 100 ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        } 
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
lappend valdict s_i_id_$bld_cnt $s_i_id s_w_id_$bld_cnt $s_w_id s_quantity_$bld_cnt $s_quantity s_dist_01_$bld_cnt $s_dist_01 s_dist_02_$bld_cnt $s_dist_02 s_dist_03_$bld_cnt $s_dist_03 s_dist_04_$bld_cnt $s_dist_04 s_dist_05_$bld_cnt $s_dist_05 s_dist_06_$bld_cnt $s_dist_06 s_dist_07_$bld_cnt $s_dist_07 s_dist_08_$bld_cnt $s_dist_08 s_dist_09_$bld_cnt $s_dist_09 s_dist_10_$bld_cnt $s_dist_10 s_data_$bld_cnt $s_data s_ytd_$bld_cnt 0 s_order_cnt_$bld_cnt 0 s_remote_cnt_$bld_cnt 0
incr bld_cnt
      if { ![ expr {$s_i_id % 100} ] } {
if [catch {set rs [ $stmnt execute $valdict ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
       }
	set bld_cnt 1
	unset valdict
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	$stmnt close
	puts "Stock done"
	return
}

proc District { odbc w_id DIST_PER_WARE loadtype } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set insupsert [ SetLoadString $loadtype ]
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
if [ catch {set stmnt [ odbc prepare "$insupsert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ($d_id, $d_w_id, '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', $d_tax, $d_ytd, $d_next_o_id)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
     }
   }
	puts "District done"
	return
}

proc LoadWare { odbc ware_start count_ware MAXITEMS DIST_PER_WARE loadtype } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set insupsert [ SetLoadString $loadtype ]
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
if [ catch {set stmnt [ odbc prepare "$insupsert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ($w_id, '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', $w_tax, $w_ytd)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
      }
puts "Start:[ clock format [ clock seconds ] ]"
	Stock odbc $w_id $MAXITEMS $loadtype
	District odbc $w_id $DIST_PER_WARE $loadtype
puts "End:[ clock format [ clock seconds ] ]"
      }
}

proc LoadCust { odbc ware_start count_ware CUST_PER_DIST DIST_PER_WARE loadtype } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer odbc $d_id $w_id $CUST_PER_DIST $loadtype
		}
	}
	return
}

proc LoadOrd { odbc ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE loadtype } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
        if {[string match windows $::tcl_platform(platform)]} {
	OrdersforWindows odbc $d_id $w_id $MAXITEMS $ORD_PER_DIST $loadtype
			} else {
	Orders odbc $d_id $w_id $MAXITEMS $ORD_PER_DIST $loadtype
			}
		}
	}
	return
}

proc connect_string { dsn odbc_driver server uid pwd } {
        if {[string match windows $::tcl_platform(platform)]} {
puts "WARNING:BUILD PERFORMANCE SIGNIFCANTLY LOWER ON WINDOWS, LINUX RECOMMENDED" 
set connection "Driver=$odbc_driver;DSN=$dsn;SERVER=$server;UID=$uid;PWD=$pwd"
	} else {
set connection "Driver=$odbc_driver;DSN=$dsn;UID=$uid;PWD=$pwd"
	}
return $connection
}

proc do_tpcc { dsn odbc_driver server port uid pwd count_ware schema num_vu loadtype load_data build_jsps nodelist copyremote } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if {[string match windows $::tcl_platform(platform)] && $odbc_driver eq "Trafodion"} {
puts "For Windows Client ODBC Driver Name is TRAF ODBC 1.0 or higher and not Trafodion"
	}
set server "TCP:$server/$port"
#force fixed schema of tpcc as stored procedures do
set schema tpcc
if { $build_jsps eq "false" && $load_data eq "false" } {
puts "You have chosen to neither load data or create JSPs"
puts "EXIT WITH NO ACTION TAKEN"
return
	}
#jsps 0 for create all, 1 for just jsps but no data, anything > 1 for date but no jsps
if { $build_jsps eq "true" && $load_data eq "true" } {
set jsps 0 } else {
if { $build_jsps eq "true" && $load_data eq "false" } {
set jsps 1 } else {
set jsps 2
		}
	    }
set connection [ connect_string $dsn $odbc_driver $server $uid $pwd ]
if { $num_vu > $count_ware } { set num_vu $count_ware }
if { $num_vu > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
switch $myposition {
        1 {
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
                        }
tsv::set application load "WAIT"
                }
        }
        default {
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_vu 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $schema ] SCHEMA"
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
puts "Trafodion connected"
#odbc configure -encoding utf-16
if { $jsps eq 1 } {
if {[string match windows $::tcl_platform(platform)]} {
puts "Stored Procedure build chosen but cannot be done on Windows"
	} else {
puts "Creating Stored Procedures Only"
SetSchema odbc $schema
CreateStoredProcs odbc $schema $nodelist $copyremote
puts "Stored Procedures Only Complete"
	}
return
	} else {
CreateSchema odbc $schema
SetSchema odbc $schema
CreateTables odbc $schema
	}
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems odbc $MAXITEMS $loadtype
puts "Monitoring Workers..."
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
LoadItems odbc $MAXITEMS $loadtype
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
if { [ tsv::exists application load ] } {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
}
after 5000
}
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
SetSchema odbc $schema
#Usually set autocommit off here
#odbc set autocommit off 
} 
if { [ expr $num_vu + 1 ] > $count_ware } { set num_vu $count_ware }
set chunk [ expr $count_ware / $num_vu ]
set rem [ expr $count_ware % $num_vu ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_vu + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare odbc $mystart $myend $MAXITEMS $DIST_PER_WARE $loadtype
LoadCust odbc $mystart $myend $CUST_PER_DIST $DIST_PER_WARE $loadtype
LoadOrd odbc $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE $loadtype
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
odbc close
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
odbc close
#LogOff and reconnect due to Issue with COMMUNICATION LINK FAILURE. THE SERVER TIMED OUT OR DISAPPEARED occuring after a connection has been idle waiting for workers to complete. 
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
if { $jsps eq 0 } {
if {[string match windows $::tcl_platform(platform)]} {
puts "Cannot build stored procedures on Windows"
	} else {
SetSchema odbc $schema
CreateStoredProcs odbc $schema $nodelist $copyremote
		}
	}
SetSchema odbc $schema
CreateIndexes odbc $schema
UpdateStatistics odbc $schema
odbc close
	}
puts "End:[ clock format [ clock seconds ] ]"
puts "[ string toupper $schema ] SCHEMA COMPLETE"
return
		}
	}
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpcc $trafodion_dsn $trafodion_odbc_driver $trafodion_server $trafodion_port $trafodion_userid $trafodion_password $trafodion_count_ware $trafodion_schema $trafodion_num_vu $trafodion_load_type $trafodion_load_data $trafodion_build_jsps {$trafodion_node_list} $trafodion_copy_remote"
	} else { return }
}

proc loadtraftpcc {} {
global _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict trafodion library ]} {
        set library [ dict get $dbdict trafodion library ]
} else { set library "tdbc::odbc" }
upvar #0 configtrafodion configtrafodion
#set variables to values in dict
setlocaltpccvars $configtrafodion
dict for {descriptor attributes} $configtrafodion {
if {$descriptor eq "connection" || $descriptor eq "tpcc" } {
foreach { val } [ dict keys $attributes ] {
variable $val
if {[dict exists $attributes $val]} {
set $val [ dict get $attributes $val ]
}}}}
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Trafodion TPROC-C"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Trafodion Library
set total_iterations $trafodion_total_iterations;# Number of transactions before logging off
set RAISEERROR \"$trafodion_raiseerror\" ;# Exit script on Trafodion error (true or false)
set KEYANDTHINK \"$trafodion_keyandthink\" ;# Time for user thinking and keying (true or false)
set odbc_driver \"$trafodion_odbc_driver\" ;# ODBC Driver default Trafodion for Linux and TRAF ODBC 1.0 for Windows
set dsn \"$trafodion_dsn\" ;# ODBC Datasource Name
set server \"TCP:$trafodion_server/$trafodion_port\" ;# Trafodion Server and Port in Trafodion format
set user \"$trafodion_userid\" ;# User ID for the Trafodion user
set password \"$trafodion_password\" ;# Password for the Trafodion user
set schema \"$trafodion_schema\" ;# Schema containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
#CONNECT STRING
proc connect_string { dsn odbc_driver server uid pwd } {
        if {[string match windows $::tcl_platform(platform)]} {
set connection "Driver=$odbc_driver;DSN=$dsn;SERVER=$server;UID=$uid;PWD=$pwd"
        } else {
set connection "Driver=$odbc_driver;DSN=$dsn;UID=$uid;PWD=$pwd"
        }
return $connection
}

#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#NEW ORDER
proc neword { odbc neword_st no_w_id no_max_w_id RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set no_o_ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
#set as CURRENT in statement
if [catch { $neword_st foreach row {
puts -nonewline "$no_w_id $no_max_w_id $no_d_id $no_c_id $no_o_ol_cnt: "
puts "$row"
} } message ] {
puts "Failed to execute new order"
if { $RAISEERROR } {
error $message
	}
}
}
#PAYMENT
proc payment { odbc payment_st p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
set p_c_credit "GC"
set p_c_balance 0.00
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set p_c_last [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
#set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
if [catch { $payment_st foreach row {
puts -nonewline "$p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $p_c_last $p_c_credit $p_c_balance: "
puts "$row"
} } message ] {
puts "Failed to execute payment"
if { $RAISEERROR } {
error $message
	}
}
}
#ORDER_STATUS
proc ostat { odbc ostat_st os_w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set os_d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set os_c_last [ randname $nrnd ]
set os_c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if [catch { $ostat_st foreach row {
puts -nonewline "$os_w_id $os_d_id $os_c_id $byname $os_c_last: "
puts "$row"
} } message ] {
puts "Failed to execute order status"
if { $RAISEERROR } {
error $message
	}
}
}
#DELIVERY
proc delivery { odbc delivery_st d_w_id RAISEERROR } {
set d_o_carrier_id [ RandomNumber 1 10 ]
if [catch { $delivery_st foreach row {
#Delivery uses print so no inline output
puts "$row"
} } message ] {
puts "Failed to execute delivery"
if { $RAISEERROR } {
error $message
	}
} else {
puts "$d_w_id $d_o_carrier_id"
	}
}
#STOCK LEVEL
proc slev { odbc slev_st w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
set st_w_id $w_id 
set st_d_id $stock_level_d_id 
if [catch { $slev_st foreach row {
puts -nonewline "$w_id $stock_level_d_id $threshold: "
puts "$row"
} } message ] {
puts "Failed to execute stock level"
if { $RAISEERROR } {
error $message
	}
}  
}
proc prep_statement { odbc statement_st } {
switch $statement_st {
slev_st {
if [ catch {set slev_st [ odbc prepare "call STOCKLEVEL(:st_w_id,:st_d_id,:threshold,:st_o_id,:stock_count)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $slev_st
	}
   }
delivery_st {
if [ catch {set delivery_st [ odbc prepare "call DELIVERY(:d_w_id,:d_o_carrier_id,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $delivery_st
	}
   }
ostat_st {
if [ catch {set ostat_st [ odbc prepare "call ORDERSTATUS(:os_w_id,:os_d_id,:os_c_id,:byname,:os_c_last,:os_c_first,:os_c_middle,:os_c_balance,:os_o_id,:os_entdate,:os_o_carrier_id)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $ostat_st
	}
   }
payment_st {
if [ catch {set payment_st [ odbc prepare "call PAYMENT(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,:p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,:p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,:p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,:p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,:p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,:p_c_discount,:p_c_balance,:p_c_data,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
return $payment_st
        }
   }
neword_st {
if [ catch {set neword_st [ odbc prepare "call NEWORDER(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,:no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,:no_d_tax,:no_w_tax,:no_d_next_o_id,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
return $neword_st
        }
     }
  }
}
#RUN TPC-C
set connection [ connect_string $dsn $odbc_driver $server $user $password ]
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
puts "Trafodion connected"
#odbc configure -encoding utf-16
   }
if [ catch {set stmnt [ odbc prepare "set schema tpcc" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Set Schema $schema"
error $message
} else {
$rs close
$stmnt close
    }
}
foreach st {neword_st payment_st slev_st delivery_st ostat_st} { set $st [ prep_statement odbc $st ] }
if [ catch {set stmnt [ odbc prepare "select max(w_id) from warehouse" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set w_id_input  [dict get $row (EXPR)]
} } message ] {
puts "Failed to get max w_id"
error $message
} else {
$stmnt close
  }
}
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
if [ catch {set stmnt [ odbc prepare "select max(d_id) from district" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set d_id_input  [dict get $row (EXPR)]
} } message ] {
puts "Failed to get Max d_id"
error $message
} else {
$stmnt close
  }
}
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword odbc $neword_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment odbc $payment_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery odbc $delivery_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev odbc $slev_st $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat odbc $ostat_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
odbc close}
}

proc loadtimedtraftpcc {} {
global opmode _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict trafodion library ]} {
        set library [ dict get $dbdict trafodion library ]
} else { set library "tdbc::odbc" }
upvar #0 configtrafodion configtrafodion
#set variables to values in dict
setlocaltpccvars $configtrafodion
dict for {descriptor attributes} $configtrafodion {
if {$descriptor eq "connection" || $descriptor eq "tpcc" } {
foreach { val } [ dict keys $attributes ] {
variable $val
if {[dict exists $attributes $val]} {
set $val [ dict get $attributes $val ]
}}}}
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Trafodion TPROC-C Timed"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#THIS SCRIPT TO BE RUN WITH VIRTUAL USER OUTPUT ENABLED
#EDITABLE OPTIONS##################################################
set library $library ;# Trafodion Library
set total_iterations $trafodion_total_iterations;# Number of transactions before logging off
set RAISEERROR \"$trafodion_raiseerror\" ;# Exit script on Trafodion error (true or false)
set KEYANDTHINK \"$trafodion_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $trafodion_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $trafodion_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set odbc_driver \"$trafodion_odbc_driver\" ;# ODBC Driver default Trafodion for Linux and TRAF ODBC 1.0 for Windows
set dsn \"$trafodion_dsn\" ;# ODBC Datasource Name
set server \"TCP:$trafodion_server/$trafodion_port\" ;# Trafodion Server and Port in Trafodion format
set user \"$trafodion_userid\" ;# User ID for the Trafodion user
set password \"$trafodion_password\" ;# Password for the Trafodion user
set schema \"$trafodion_schema\" ;# Schema containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

if { [ chk_thread ] eq "FALSE" } {
error "Trafodion Timed Script must be run in Thread Enabled Interpreter"
}
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
#CONNECT STRING
proc connect_string { dsn odbc_driver server uid pwd } {
        if {[string match windows $::tcl_platform(platform)]} {
set connection "Driver=$odbc_driver;DSN=$dsn;SERVER=$server;UID=$uid;PWD=$pwd"
        } else {
set connection "Driver=$odbc_driver;DSN=$dsn;UID=$uid;PWD=$pwd"
        }
return $connection
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Primary" } {
set connection [ connect_string $dsn $odbc_driver $server $user $password ]
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
puts "Trafodion connected"
#odbc configure -encoding utf-16
   }
if [ catch {set stmnt [ odbc prepare "set schema tpcc" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Set Schema $schema"
error $message
} else {
$rs close
$stmnt close
    }
}
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
puts "Rampup complete, Taking start Transaction Count."
#No current statement for querying Trafodion transactions ie commits + rollbacks
set start_trans 0
if [ catch {set stmnt [ odbc prepare "select sum(d_next_o_id) from district" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set start_nopm [dict get $row (EXPR)]
} } message ] {
puts "Failed to query district table"
error $message
} else {
$stmnt close
  }
}
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
#No current statement for querying Trafodion transactions ie commits + rollbacks
set end_trans 0
if [ catch {set stmnt [ odbc prepare "select sum(d_next_o_id) from district" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set end_nopm [dict get $row (EXPR)]
} } message ] {
puts "Failed to query district table"
error $message
} else {
$stmnt close 
  }
}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "[ expr $totalvirtualusers - 1 ] Active Virtual Users configured"
puts [ testresult $nopm $tpm Trafodion ]
tsv::set application abort 1
if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
odbc close
		} else {
puts "Operating in Replica Mode, No Snapshots taken..."
		}
	}
default {
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#NEW ORDER
proc neword { odbc neword_st no_w_id no_max_w_id RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set no_o_ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
#set as CURRENT in statement
if [catch { $neword_st foreach row { ; } } message ] {
puts "Failed to execute new order"
if { $RAISEERROR } {
error $message
	}
}
}
#PAYMENT
proc payment { odbc payment_st p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
set p_c_credit "GC"
set p_c_balance 0.00
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set p_c_last [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
#set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
if [catch { $payment_st foreach row { ; } } message ] {
puts "Failed to execute payment"
if { $RAISEERROR } {
error $message
	}
}
}
#ORDER_STATUS
proc ostat { odbc ostat_st os_w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set os_d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set os_c_last [ randname $nrnd ]
set os_c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if [catch { $ostat_st foreach row { ; } } message ] {
puts "Failed to execute order status"
if { $RAISEERROR } {
error $message
	}
}
}
#DELIVERY
proc delivery { odbc delivery_st d_w_id RAISEERROR } {
set d_o_carrier_id [ RandomNumber 1 10 ]
if [catch { $delivery_st foreach row { ; } } message ] {
puts "Failed to execute delivery"
if { $RAISEERROR } {
error $message
	}
} else { ; }
}
#STOCK LEVEL
proc slev { odbc slev_st w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
set st_w_id $w_id 
set st_d_id $stock_level_d_id 
if [catch { $slev_st foreach row { ; } } message ] {
puts "Failed to execute stock level"
if { $RAISEERROR } {
error $message
	}
}  
}
proc prep_statement { odbc statement_st } {
switch $statement_st {
slev_st {
if [ catch {set slev_st [ odbc prepare "call STOCKLEVEL(:st_w_id,:st_d_id,:threshold,:st_o_id,:stock_count)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $slev_st
	}
   }
delivery_st {
if [ catch {set delivery_st [ odbc prepare "call DELIVERY(:d_w_id,:d_o_carrier_id,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $delivery_st
	}
   }
ostat_st {
if [ catch {set ostat_st [ odbc prepare "call ORDERSTATUS(:os_w_id,:os_d_id,:os_c_id,:byname,:os_c_last,:os_c_first,:os_c_middle,:os_c_balance,:os_o_id,:os_entdate,:os_o_carrier_id)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $ostat_st
	}
   }
payment_st {
if [ catch {set payment_st [ odbc prepare "call PAYMENT(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,:p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,:p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,:p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,:p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,:p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,:p_c_discount,:p_c_balance,:p_c_data,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
return $payment_st
        }
   }
neword_st {
if [ catch {set neword_st [ odbc prepare "call NEWORDER(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,:no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,:no_d_tax,:no_w_tax,:no_d_next_o_id,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
return $neword_st
        }
     }
  }
}
#RUN TPC-C
set connection [ connect_string $dsn $odbc_driver $server $user $password ]
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
puts "Trafodion connected"
#odbc configure -encoding utf-16
   }
if [ catch {set stmnt [ odbc prepare "set schema tpcc" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Set Schema $schema"
error $message
} else {
$rs close
$stmnt close
    }
}
foreach st {neword_st payment_st slev_st delivery_st ostat_st} { set $st [ prep_statement odbc $st ] }
if [ catch {set stmnt [ odbc prepare "select max(w_id) from warehouse" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set w_id_input  [dict get $row (EXPR)]
} } message ] {
puts "Failed to get max w_id"
error $message
} else {
$stmnt close
  }
}
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
if [ catch {set stmnt [ odbc prepare "select max(d_id) from district" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set d_id_input  [dict get $row (EXPR)]
} } message ] {
puts "Failed to get Max d_id"
error $message
} else {
$stmnt close
  }
}
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword odbc $neword_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment odbc $payment_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery odbc $delivery_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev odbc $slev_st $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat odbc $ostat_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
odbc close
}
}}
}
