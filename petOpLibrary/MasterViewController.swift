//
//  MasterViewController.swift
//  petOpLibrary
//
//  Created by mac on 4/9/16.
//  Copyright © 2016 Juan Sebastian Castro. All rights reserved.
//

import UIKit
import CoreData

struct Libro {
    var isbn : String
    var titulo : String
    var portada : UIImage
    var autores : [String]
    
    
    init(isbn : String, titulo : String, portada : UIImage, autores : [String]){
        self.isbn  = isbn
        self.titulo = titulo
        self.portada = portada
        self.autores = autores
    }
}

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var detailViewController: DetailViewController? = nil
    //var managedObjectContext: NSManagedObjectContext? = nil
    //var viewController : ViewController? = nil
    
    var objetos = [AnyObject]()
    var libroStruct = [Libro]()
    
    var contexto : NSManagedObjectContext? = nil


    
    @IBOutlet weak var buscarLibro: UITextField!
    
    @IBAction func buscarLibro(var sender: UITextField) {
        // funcion para buscar ISBN 9780071599894 y/o 978-84-376-0494-7
        let libroEntidad = NSEntityDescription.entityForName("Libro", inManagedObjectContext: self.contexto!)
        let request = libroEntidad?.managedObjectModel.fetchRequestFromTemplateWithName("obtenerLibro", substitutionVariables: ["isbn": sender.text!])
        
        do { let buscarLibroEntidad = try self.contexto?.executeFetchRequest(request!)
            if (buscarLibroEntidad?.count > 0){
                print("Este libro ya existe")
                return
            }
            
        } catch {
            
        }
        
        
        let libroResultado : Libro = buscarEnOpenLib(sender as! UITextField)
        if (libroResultado.titulo != "") {
            let nuevaEntidadLibro = NSEntityDescription.insertNewObjectForEntityForName("Libro", inManagedObjectContext: self.contexto!)
            
            nuevaEntidadLibro.setValue(libroResultado.isbn, forKey: "isbn")
            nuevaEntidadLibro.setValue(libroResultado.titulo, forKey: "titulo")
            nuevaEntidadLibro.setValue(UIImagePNGRepresentation(libroResultado.portada), forKey: "portada")
            nuevaEntidadLibro.setValue(crearEntidadAutores(libroResultado.autores), forKey: "tiene")
            
            do{
                try self.contexto?.save()
            } catch{
                
            }
            
            libroStruct.append(libroResultado)
            self.tableView!.reloadData()
            sender.text = ""
            sender.resignFirstResponder()
            
            /* Trying to push the detail view programatically */
            let lastSectionIndex = self.tableView.numberOfSections-1
            let lastSectionLastRow = self.tableView.numberOfRowsInSection(lastSectionIndex) - 1
            let indexPath = NSIndexPath(forRow:lastSectionLastRow, inSection: lastSectionIndex)
            // let cell = tableView.cellForRowAtIndexPath(indexPath)
            // print(cell?.textLabel?.text)
            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
            self.performSegueWithIdentifier("showDetail", sender: nil )
        }
        
        
    }//func
    
   
    func crearEntidadAutores(autores : [String]) -> Set<NSObject> {
        var entidades = Set<NSObject>()
        
        for autor in autores{
            let autorEntidad = NSEntityDescription.insertNewObjectForEntityForName("Autor", inManagedObjectContext: self.contexto!)
            autorEntidad.setValue(autor, forKey: "nombre")
            entidades.insert(autorEntidad)
        }
        return entidades
    }
    
    
    
    
    func buscarEnOpenLib(sender: UITextField) -> Libro {
        let isbn : String = sender.text!
        
        
        var libros : Libro = Libro(isbn: isbn, titulo : "", portada: UIImage() , autores: [])
        
        
        let urls = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:\(isbn)"
        let safeURL = urls.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let url = NSURL(string: safeURL)
        let datos:NSData? = NSData(contentsOfURL: url!)
        let texto = NSString(data:datos!, encoding: NSUTF8StringEncoding)
        if texto == "{}" || texto == "" {
            let alerta = UIAlertController(title: "Resultado", message: "Informacion no encontrada", preferredStyle: UIAlertControllerStyle.Alert)
            alerta.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alerta, animated: true, completion: nil)
            sender.text = "";
        } else if texto == nil {
            let alerta = UIAlertController(title: "Resultado", message: "Por favor verifique la conexion a Internet", preferredStyle: UIAlertControllerStyle.Alert)
            alerta.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alerta, animated: true, completion: nil)
            sender.text = "";
        } else {
            libros =  self.parceBooksJson(datos!, isbn: isbn)
            
        }
        
        return libros
    }
    
    
    func parceBooksJson(nsdata: NSData, isbn: String) -> Libro {
        var libroDato : Libro = Libro(isbn: "", titulo : "", portada: UIImage() , autores: [])
        
        do {
            
            let jsonFull = try NSJSONSerialization.JSONObjectWithData(nsdata, options: NSJSONReadingOptions.MutableContainers) as! [String: AnyObject]
            let arregloLibro = jsonFull as NSDictionary
            for (_, value) in arregloLibro {
                // Proceso Titulo del Libro
                let titulo  = value["title"] as! String
                
                // Proceso Lista de Autores
                let autores = value["authors"]! != nil ? value["authors"] as! NSArray : []
                var autoresArreglo : [String] = [String]()
                for autor in autores {
                    let nombreAutor = autor["name"] as! String
                    autoresArreglo.append(nombreAutor)
                }
                
                // Proceso Portada de Libro
                var portada : UIImage = UIImage(named: "Sinportada")!
                
                if value["cover"] != nil {
                    let imageUrls = value["cover"]??["large"]
                    if imageUrls != nil {
                        let url = NSURL(string: imageUrls as! String)
                        let data = NSData(contentsOfURL: url!)
                        portada = UIImage(data: data!)!
                    }
                }
                
                libroDato = Libro(isbn : isbn, titulo : titulo, portada: portada , autores: autoresArreglo)
            }
            
            
        } catch {
            print("Error")
            
        }
        
        return libroDato
    }
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.contexto = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "habilitaBuscarLibro:")
        //let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        // CARGA DATOS
        self.contexto = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let seccionEntity = NSEntityDescription.entityForName("Libro", inManagedObjectContext: self.contexto!)
        
        let request = seccionEntity?.managedObjectModel.fetchRequestTemplateForName("obtenerLibros")
        do{
            let bookEntities = try self.contexto?.executeFetchRequest(request!)
            for bookEntity in bookEntities! {
                let titulo = bookEntity.valueForKey("titulo") as! String
                let isbn = bookEntity.valueForKey("isbn") as! String
                let portada : UIImage = UIImage(data: bookEntity.valueForKey("portada") as! NSData)!
                
                let authorEntities = bookEntity.valueForKey("tiene") as! Set<NSObject>
                var authorArray = [String]()
                for authorEntity in authorEntities {
                    let author = authorEntity.valueForKey("nombre") as! String
                    authorArray.append(author)
                    
                }
                self.libroStruct.append(Libro(isbn: isbn, titulo: titulo, portada: portada, autores: authorArray))
                
            }
        } catch{
            
        }
        
    }

    
    func habilitaBuscarLibro(sender: AnyObject) {
        self.buscarLibro.hidden = false
        self.buscarLibro.resignFirstResponder()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*func insertNewObject(sender: AnyObject) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context)
             
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        newManagedObject.setValue(NSDate(), forKey: "timeStamp")
             
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }*/

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let objeto = libroStruct[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detalleItem = objeto
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return objects.count
        return libroStruct.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel!.text = libroStruct[indexPath.row].titulo
        return cell
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objetos.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
/*
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
        cell.textLabel!.text = object.valueForKey("timeStamp")!.description
    }*/

    // MARK: - Fetched results controller
/*
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Event", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //print("Unresolved error \(error), \(error.userInfo)")
             abort()
        }
        
        return _fetchedResultsController!
    }*/
/*    var _fetchedResultsController: NSFetchedResultsController? = nil

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }*/

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         self.tableView.reloadData()
     }
     */

}

