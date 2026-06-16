import os
import xml.etree.ElementTree as ET
import pandas as pd

def generate_reports(xml_file="Test Results/report.xml"):
    os.makedirs("Test Results/Excel", exist_ok=True)
    os.makedirs("Test Results/Summary", exist_ok=True)
    
    data = []
    total, passed, failed, skipped = 0, 0, 0, 0
    failed_tests = []
    
    if os.path.exists(xml_file):
        tree = ET.parse(xml_file)
        root = tree.getroot()
        
        for testsuite in root.iter('testsuite'):
            for testcase in testsuite.iter('testcase'):
                total += 1
                name = testcase.get('name')
                time = testcase.get('time')
                
                status = "Passed"
                reason = ""
                
                failure = testcase.find('failure')
                error = testcase.find('error')
                skipped_elem = testcase.find('skipped')
                
                if failure is not None:
                    status = "Failed"
                    failed += 1
                    reason = failure.get('message', 'Unknown failure')
                    failed_tests.append({"name": name, "reason": reason})
                elif error is not None:
                    status = "Failed"
                    failed += 1
                    reason = error.get('message', 'Unknown error')
                    failed_tests.append({"name": name, "reason": reason})
                elif skipped_elem is not None:
                    status = "Skipped"
                    skipped += 1
                else:
                    passed += 1
                
                data.append({
                    "Test Name": name,
                    "Status": status,
                    "Execution Time (s)": time,
                    "Failure Reason": reason
                })
    else:
        print(f"Warning: {xml_file} not found. Generating empty reports.")
        
    # Generate Excel Report
    df = pd.DataFrame(data, columns=["Test Name", "Status", "Execution Time (s)", "Failure Reason"])
    excel_path = "Test Results/Excel/Automation_Test_Report.xlsx"
    df.to_excel(excel_path, index=False)
    print(f"Excel report generated at {excel_path}")
    
    # Generate Markdown Summary
    pass_percentage = (passed / total * 100) if total > 0 else 0
    base_url = os.environ.get("BASE_URL", "N/A")
    
    md_content = f"""# Live GitHub Pages E2E Test Summary

**Deployment URL:**
{base_url}

**Total Tests:** {total}
- **Passed:** {passed}
- **Failed:** {failed}
- **Skipped:** {skipped}
- **Pass Percentage:** {pass_percentage:.2f}%

"""
    
    if failed > 0:
        md_content += "### Failed Tests:\n"
        for ft in failed_tests:
            md_content += f"- **{ft['name']}**\n  - Reason: {ft['reason']}\n"
            
    with open("Test Results/Summary/summary.md", "w") as f:
        f.write(md_content)
        
    print("Markdown summary generated at Test Results/Summary/summary.md")

if __name__ == "__main__":
    generate_reports()
