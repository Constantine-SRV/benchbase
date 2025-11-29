package com.oltpbenchmark.benchmarks.chbenchmark.queries;
import com.oltpbenchmark.api.SQLStmt;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
public class Q15 extends GenericQuery {
  @Override
  protected SQLStmt get_query() {
    // Метод обязателен из-за GenericQuery, но здесь не используется
    return null;
  }
  @Override
  public void run(Connection conn) throws SQLException {
    // создаём уникальное имя для view, зависящее от потока
    String viewName = "revenue_" + Thread.currentThread().threadId();
    String createSQL =
        "CREATE VIEW " + viewName + " (supplier_no, total_revenue) AS "
            + "SELECT mod((s_w_id * s_i_id),10000) as supplier_no, "
            + "sum(ol_amount) as total_revenue "
            + "FROM order_line, stock "
            + "WHERE ol_i_id = s_i_id "
            + "AND ol_supply_w_id = s_w_id "
            + "AND ol_delivery_d >= '2007-01-02 00:00:00.000000' "
            + "GROUP BY supplier_no";
    String querySQL =
        "SELECT su_suppkey, su_name, su_address, su_phone, total_revenue "
            + "FROM supplier, " + viewName + " "
            + "WHERE su_suppkey = supplier_no "
            + "AND total_revenue = (select max(total_revenue) from " + viewName + ") "
            + "ORDER BY su_suppkey";
    String dropSQL = "DROP VIEW " + viewName;
    try (Statement stmt = conn.createStatement()) {
      try {
        stmt.executeUpdate(createSQL);
        stmt.executeQuery(querySQL);
      } finally {
        stmt.executeUpdate(dropSQL);
      }
    }
  }
}
