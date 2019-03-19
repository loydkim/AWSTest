//
//  ViewController.swift
//  AwsTest
//
//  Created by YOUNGSIC KIM on 2019-03-04.
//  Copyright © 2019 YOUNGSIC KIM. All rights reserved.
//

import UIKit
import AWSAppSync

enum SelectedQuery{
    case INSERT
    case UPDATE
    case SELECT
    case DELETE
}

class ViewController: UIViewController {
    
    @IBOutlet weak var addDataView: UIView! {
        didSet {
            addDataView.isHidden = true
        }
    }
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var desctiptionLabel: UILabel!
    
    @IBOutlet weak var choiceButton: UILabel!
    @IBOutlet weak var selectedTable: UITableView! {
        didSet {
            selectedTable.isHidden = true
        }
    }
    var selectedQuery: SelectedQuery!
    var nameArray:NSMutableArray = NSMutableArray()
    var descriptionArray:NSMutableArray = NSMutableArray()
    
    var appSyncClient: AWSAppSyncClient?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appSyncClient = appDelegate.appSyncClient
    }
    
    // MARK: StoryBoard Actions
    
    @IBAction func insertAction() {
        showView()
        idTextField.isHidden = true
        idLabel.isHidden = true
        selectedQuery = SelectedQuery.INSERT
    }
    
    @IBAction func updateAction() {
        showView()
        selectedQuery = SelectedQuery.UPDATE
    }
    
    @IBAction func selectAction() {
        addDataView.isHidden = true
        selectedTable.isHidden = false
        selectedQuery = SelectedQuery.SELECT
        selectData()
    }
    
    @IBAction func delectAction() {
        showView()
        nameLabel.isHidden = true
        nameTextField.isHidden = true
        desctiptionLabel.isHidden = true
        descriptionTextField.isHidden = true
        selectedQuery = SelectedQuery.DELETE
    }
    
    @IBAction func doItNow() {
        switch selectedQuery {
        case .INSERT?:
            if nameTextField.text!.count < 1 || descriptionTextField.text!.count < 1 {
                showAlert(messageString: "You have to insert data")
            }else {
                insertData()
            }
            break
        case .UPDATE?:
            if idTextField.text!.count < 1 || nameTextField.text!.count < 1 || descriptionTextField.text!.count < 1 {
                showAlert(messageString: "You have to insert data")
            }else {
                updateData()
            }
            break
        case .DELETE?:
            if idTextField.text!.count < 1{
                showAlert(messageString: "You have to insert data")
            }else {
                deleteData()
            }
            break
        case .SELECT?:
            selectData()
            break
        case .none:
            break
        }
    }
    
    func showView() {
        choiceButton.isHidden = true
        selectedTable.isHidden = true
        addDataView.isHidden = false
        idLabel.isHidden = false
        nameLabel.isHidden = false
        desctiptionLabel.isHidden = false
        idTextField.isHidden = false
        idTextField.text = ""
        nameTextField.isHidden = false
        nameTextField.text = ""
        descriptionTextField.isHidden = false
        descriptionTextField.text = ""
        
    }
    
    func showAlert(messageString: String) {
        let alertController = UIAlertController(title: "Alert Message", message: messageString, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: AWS APIs
    
    func insertData(){
        let insertQuery = CreateTodoInput(name: nameTextField.text!, description:descriptionTextField.text!)
        appSyncClient?.perform(mutation: CreateTodoMutation(input: insertQuery)) { (result, error) in
            self.selectData()
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred: \(error.localizedDescription )")
            }else if let resultError = result?.errors {
                print("Error saving the item on server: \(resultError)")
                return
            }else {
                self.showAlert(messageString: "Success Insert Data!! \n Check data in server !")
                print("Success Insert Data")
            }
        }
    }
    
    func selectData(){
        let selectQuery = ListTodosQuery()
//        var filter = ModelTodoFilterInput()
//        var nameString = ModelStringFilterInput()
//        nameString.eq = "Name2"
//        filter.name = nameString
//        selectQuery.filter = filter
        appSyncClient?.fetch(query: selectQuery, cachePolicy: .fetchIgnoringCacheData) {(result, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                return
            }
            result?.data?.listTodos?.items!.forEach {
                
                print(($0?.name)! + " " + ($0?.description)!)
                self.nameArray.add(($0?.name)!)
                self.descriptionArray.add(($0?.description)!)
                self.selectedTable.reloadData()
            }
        }
    }
    
    func updateData() {
        var updateQuery = UpdateTodoInput(id: idTextField.text!)
        updateQuery.name = nameTextField.text!
        updateQuery.description = descriptionTextField.text!
        appSyncClient?.perform(mutation: UpdateTodoMutation(input: updateQuery)) { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred: \(error.localizedDescription )")
            }else if let resultError = result?.errors {
                print("Error saving the item on server: \(resultError)")
                return
            }else {
                self.showAlert(messageString: "Success Update Data!! \n Check data in server !")
                print("Success Update Data")
            }
        }
    }
    
    func deleteData() {
        let deleteQuery = DeleteTodoInput(id: idTextField.text!)
        appSyncClient?.perform(mutation: DeleteTodoMutation(input: deleteQuery)) { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred: \(error.localizedDescription )")
            }else if let resultError = result?.errors {
                print("Error saving the item on server: \(resultError)")
                return
            }else {
                self.showAlert(messageString: "Success Delete Data!! \n Check data in server !")
                print("Success Delete Data")
            }
        }
    }
}

extension ViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nameArray.count < 1 {
            return 1
        }else {
            return nameArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "tableCell")!
        if nameArray.count < 1 {
            cell.textLabel?.text = "No data"
        }else {
            cell.textLabel?.text = nameArray[indexPath.row] as? String
            cell.detailTextLabel?.text = descriptionArray[indexPath.row] as? String
        }
        return cell
    }
}
