package com.oltpbenchmark.benchmarks.chbenchmark.queries;

import com.oltpbenchmark.api.SQLStmt;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Q15 extends GenericQuery {
  
  // Держим dummy SQLStmt для совместимости с GenericQuery
  // Он нужен чтобы getName() работал правильно
  private final SQLStmt dummyStmt = new SQLStmt("Q15");
  
  @Override
  protected SQLStmt get_query() {
    // Возвращаем dummy объект вместо null
    return dummyStmt;
  }
  
  @Override
  public void run(Connection conn) throws SQLException {
    // Создаём уникальное имя для view, зависящее от потока
    // threadId() - правильный метод для Java 19+
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
            + "AND total_revenue = (SELECT max(total_revenue) FROM " + viewName + ") "
            + "ORDER BY su_suppkey";
    
    String dropSQL = "DROP VIEW IF EXISTS " + viewName;
    
    try (Statement stmt = conn.createStatement()) {
      try {
        stmt.executeUpdate(createSQL);
        // ВАЖНО: ResultSet нужно закрыть!
        try (ResultSet rs = stmt.executeQuery(querySQL)) {
          while (rs.next()) {
            // Проходим по результатам (для совместимости с бенчмарком)
          }
        }
      } finally {
        // DROP всегда выполнится, даже если запрос упал
        try {
          stmt.executeUpdate(dropSQL);
        } catch (SQLException e) {
          // Игнорируем ошибку если VIEW уже не существует
        }
      }
    }
  }
}
