*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Tables
Library    RPA.Archive
Library    OperatingSystem
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault
#Library    RPA.FileSystem

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    secret
    Log    ${secret}[url]
    Wait Until Keyword Succeeds    10x    2 sec    Open Available Browser    ${secret}[url]
    Wait Until Page Contains Element    css:button[class="btn btn-dark"]

Download The CSV file
    ${url}=    Input form dialog
    Download    ${url}    overwrite=True

Get orders
    Download The CSV file
    @{orders}=    Read table from CSV    orders.csv
    [Return]    @{orders}

Close the annoying modal
    Click Button When Visible    css:button[class="btn btn-dark"]

Fill the form
    [Arguments]    ${head}    ${body}    ${legs}    ${address}
    Log    ${head}
    Select From List By Index    name:head    ${head}
    Click Element    css:label[for=id-body-${body}]
    Input Text    css:input[type="number"]    ${legs}
    Input Text    css:input[type="text"]    ${address}
    Click Button    Preview
    Wait Until Page Contains
    ...    Admire your robot
    ...    0.5s

Submit the order
    Wait Until Keyword Succeeds    10x    2 sec    Click Button    Order
    Wait Until Element Is Visible    id:receipt

Store the order receipt as a PDF file
    [Arguments]    ${name}
    ${tempPdf} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${tempPdf}    ${CURDIR}${/}output${/}${name}.pdf
    [Return]    ${CURDIR}${/}output${/}${name}.pdf

Take a screenshot of the robot image
    [Arguments]    ${name}
    ${screenShot} =    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${name}.png
    [Return]    ${CURDIR}${/}output${/}${name}.png

Add ScreenShot To PDF
    [Arguments]    ${pdfPath}    @{imagePath}
    Add Files To Pdf    ${imagePath}    ${pdfPath}    True

Fill All Orders
    @{orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}[Head],${row}[Body],${row}[Legs],${row}[Address]
        Fill the form    ${row}[Head]   ${row}[Body]    ${row}[Legs]    ${row}[Address]
        Wait Until Keyword Succeeds    10x    2 sec   Submit the order
        ${pdf} =    Store the order receipt as a PDF file    ${row}[Order number]
        Log    ${pdf}
        ${screenShot} =    Take a screenshot of the robot image    ${row}[Order number]
        Log    ${screenShot}
        @{images}=    Create List    ${screenShot}
        Add ScreenShot To PDF    ${pdf}    @{images}
        Wait Until Keyword Succeeds    10x    2 sec    Click Button    Order another robot
        Close the annoying modal
    END

Archive Receipts in Zip
    Archive Folder With Zip    ${CURDIR}${/}output    Receipts.zip    include=*.pdf
    Move File    ${EXECDIR}${/}Receipts.zip    ${CURDIR}${/}output

Input form dialog
    Add heading       Please enter the URL of the orders CSV file
    Add text input    url    
    ...    label=URL
    ...    placeholder=url...
    ${result}=    Run dialog
    Log    ${result.url}
    [Return]   ${result.url}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Fill All Orders
    Archive Receipts in Zip
    [Teardown]    Close Browser