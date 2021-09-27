//
//  TicketsView.swift
//  BM_Supermercados
//
//  Created by bfernandez on 23/03/2020.
//  Copyright © 2020 Intermark it. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import SVProgressHUD
import SideMenu
import ScrollableGraphView
import SkeletonView
import FittedSheets
import WWCalendarTimeSelector 

class TicketListViewCell: UITableViewCell {
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var ticketAddressMarkerWidth: NSLayoutConstraint!
    @IBOutlet weak var ticketAddress: UILabel!
    @IBOutlet weak var ticketDay: UILabel!
    @IBOutlet weak var ticketHour: UILabel!
    @IBOutlet weak var ticketValueNumber: UILabel!
    @IBOutlet weak var ticketValueDecimal: UILabel!
    @IBOutlet weak var ticketDetailButton: UIButton!
    @IBOutlet weak var ticketProductsButton: UIButton!
    @IBOutlet weak var ticketAcumulaView: UIView!
    @IBOutlet weak var ticketAcumulaTitle: UILabel!
    @IBOutlet weak var ticketAcumulaValue: UILabel!
    @IBOutlet weak var ticketAcumulaViewWidth: NSLayoutConstraint!
    @IBOutlet weak var ticketAhorroView: UIView!
    @IBOutlet weak var ticketAhorroTitle: UILabel!
    @IBOutlet weak var ticketAhorroValue: UILabel!
    @IBOutlet weak var ticketAhorroViewWidth: NSLayoutConstraint!
    @IBOutlet weak var ticketDayPosition: NSLayoutConstraint!
    @IBOutlet weak var ticketStoreIcon: UIImageView!
    
    var seeTicketDetailAction : (() -> ())?
    var seeTicketProductsAction : (() -> ())?
      
    override func awakeFromNib() {
        super.awakeFromNib()
        self.ticketDetailButton.addTarget(self, action: #selector(detailTapped(_:)), for: .touchUpInside)
        self.ticketProductsButton.addTarget(self, action: #selector(productsTapped(_:)), for: .touchUpInside)
    }
      
    @IBAction func detailTapped(_ sender: UIButton){
      seeTicketDetailAction?()
    }
    
    @IBAction func productsTapped(_ sender: UIButton){
      seeTicketProductsAction?()
    }
    
    override func layoutSubviews() {
        ViewUtils.sharedInstance.roundCorners([.bottomRight], radius: 25, view: self.backView)
        ViewUtils.sharedInstance.roundCorners([.bottomRight], radius: 25, view: self.ticketAhorroView)
        if TicketDataManager.sharedInstance.getUserTickets().count > 0 {
            guard let ticket: Ticket? = TicketDataManager.sharedInstance.getUserTickets()[self.tag] else {}
            if ticket!.importeAhorro.value! > Float(0) {
                if ticket!.importeAcumulas.value! > Float(0) {
                    ViewUtils.sharedInstance.roundCorners([.bottomRight], radius: 0, view: self.ticketAcumulaView)
                }
                else {
                    
                }
            }
            else {
                if ticket!.importeAcumulas.value! > Float(0) {
                    ViewUtils.sharedInstance.roundCorners([.bottomRight], radius: 25, view: self.ticketAcumulaView)
                }
            }
        }
    }
}

class TicketsView: BaseView, ScrollableGraphViewDataSource, WWCalendarTimeSelectorProtocol {
    
    var presenter: TicketsPresenterProtocol?
    
    var menuController: SideMenuNavigationController?
    
    var numberOfItems = 6
    lazy var plotOneData: [Double] = [0, 0, 0, 0, 0, 0]
    
    @IBOutlet weak var digitalTicketSwitch: UISwitch! {
        didSet {
            if #available(iOS 13, *) {
                digitalTicketSwitch.overrideUserInterfaceStyle = .light
            }
        }
    }
    
    @IBAction func changeTicketState(_ sender: Any) {
        if !self.digitalTicketSwitch.isSelected {
           // self.digitalTicketSwitch.isSelected = true
            // self.presenter?.changeTicketState(state: self.digitalTicketSwitch.isOn)
            
            
            let selector = WWCalendarTimeSelector.instantiate()
            selector.delegate = self
            selector.optionMainPanelBackgroundColor = .white
            selector.optionSelectionType = .range
            selector.optionShowTopContainer = false
            selector.optionShowTopPanel = false
            selector.optionLayoutHeight = self.view.frame.size.height * 0.7
            selector.optionLayoutWidth = self.view.frame.size.width * 0.9
            selector.optionCalendarLocale = "es"
                   /*
                     Any other options are to be set before presenting selector!
                   */
           self.navigationController?.present(selector, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var dateRangeLabel: UILabel!
    
    
    @IBAction func showCalendar(_ sender: Any) {
         
                let selector = WWCalendarTimeSelector.instantiate()
                selector.delegate = self
                /*
                  Any other options are to be set before presenting selector!
                */
        self.navigationController?.present(selector, animated: true, completion: nil)
            

    }
    
    
    func WWCalendarTimeSelectorDone(selector: WWCalendarTimeSelector, date: NSDate) {
        print(date)
    }
    
    @IBOutlet weak var ticketsTableView: UITableView! {
        didSet {
            ticketsTableView.register(UINib(nibName: "TicketListViewCell", bundle: Bundle.main), forCellReuseIdentifier: "ticketListCell")
            if #available(iOS 13, *) {
                ticketsTableView.overrideUserInterfaceStyle = .light
            }
        }
    }
    @IBOutlet weak var ticketsTableViewHeight: NSLayoutConstraint!
    
    @IBAction func showMenu(_ sender: Any) {
        menuController = MenuWireFrame.createMenuModule(fromView: self.tabBarController!) as? SideMenuNavigationController
        navigationController?.present(menuController!, animated: true, completion: nil)
    }
    @IBOutlet weak var topBarContentHeight: NSLayoutConstraint!
    @IBOutlet weak var networkContent: UIView!
    @IBOutlet weak var networkIndicator: UIImageView!
    @IBOutlet weak var networkText: UILabel!
    
    @IBOutlet weak var ticketAhorroView: UIView!
    @IBOutlet weak var ticketAhorroViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ticketAhorroBackView: UIView! {
        didSet {
            ViewUtils.sharedInstance.roundCorners([.allCorners], radius: 50, view: self.ticketAhorroBackView)
        }
    }
    @IBOutlet weak var ticketAhorroNumber: UILabel!
    @IBOutlet weak var ticketAhorroDecimal: UILabel!
    @IBOutlet weak var ticketScrollableGraphView: ScrollableGraphView!
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        self.ticketsTableView.isSkeletonable = true
        view.showAnimatedSkeleton(transition: .crossDissolve(0.25))
        super.viewDidLoad()
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.setHidesBackButton(true, animated:false)
        SideMenuManager.default.addPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
        presenter?.viewDidLoad()
        if AuthDataManager.sharedInstance.getUserData().associatedCliente?.clienteBasico?.ticketDigital.value != nil {
            digitalTicketSwitch.isOn = ((AuthDataManager.sharedInstance.getUserData().associatedCliente?.clienteBasico?.ticketDigital.value!) == true)
        }
        else {
            digitalTicketSwitch.isOn = false
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reloadScreen(_:)), name: Notification.Name.init("Tab.Tickets"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkChanged(_:)), name: Notification.Name.init("Network.Changed"), object: nil)
        
        //NETWORK
        if NetworkUtils.sharedInstance.isConnected() {
            self.topBarContentHeight.constant = 60
            self.networkContent.isHidden = true
        }
        else {
            self.topBarContentHeight.constant = 90
            self.networkText.text = LocaleUtils.sharedInstance.get("offline.text")
            self.networkContent.isHidden = false
        }
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if NetworkUtils.sharedInstance.isConnected() {
            self.setupGraph(graphView: self.ticketScrollableGraphView)
        }
        
        //EMMA
        EmmaUtils.sharedInstance.sendCustomEvent(token: EmmaUtils.Tokens.pantallaTickets)
      
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.digitalTicketSwitch.isSelected = false
    }
    
    @objc private func reloadScreen(_ notification: Notification) {
        view.showAnimatedSkeleton(transition: .crossDissolve(0.25))
        presenter?.viewDidLoad()
        if AuthDataManager.sharedInstance.getUserData().associatedCliente?.clienteBasico?.ticketDigital.value != nil {
            digitalTicketSwitch.isOn = ((AuthDataManager.sharedInstance.getUserData().associatedCliente?.clienteBasico?.ticketDigital.value!) == true)
        }
        else {
            digitalTicketSwitch.isOn = false
        }
    }
    
    @objc private func networkChanged(_ notification: Notification) {
        guard let reachable = notification.object as? Bool else {
            let object = notification.object as Any
            assertionFailure("Invalid object: \(object)")
            return
        }
        if reachable == true {
            self.networkContent.backgroundColor = UIColor(named: "onlineColor")
            self.networkIndicator.image = UIImage(named: "online.indicator")
            self.networkText.text = LocaleUtils.sharedInstance.get("online.text")
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
            self.topBarContentHeight.constant = 60
            self.view.setNeedsUpdateConstraints()
            UIView.animate(withDuration: 0.5, delay: 4.0, options: .beginFromCurrentState, animations: {
                self.view.layoutIfNeeded()
            }, completion: {_ in
                self.networkContent.isHidden = true
            })
        }
        else {
            self.networkContent.isHidden = false
            self.topBarContentHeight.constant = 90
            self.networkContent.backgroundColor = UIColor(named: "textLabelColor")
            self.networkIndicator.image = UIImage(named: "offline.indicator")
            self.networkText.text = LocaleUtils.sharedInstance.get("offline.text")
            self.view.setNeedsUpdateConstraints()
            UIView.animate(withDuration: 0.3, delay: 0, options: .beginFromCurrentState, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func resetSwitch(){
        self.digitalTicketSwitch.isSelected=false;
    }
    // When using Interface Builder, only add the plots and reference lines in code.
    func setupGraph(graphView: ScrollableGraphView) {

        // Setup the first line plot.
        let blueLinePlot = LinePlot(identifier: "one")

        blueLinePlot.lineWidth = 3
        blueLinePlot.lineColor = UIColor.black
        blueLinePlot.lineStyle = ScrollableGraphViewLineStyle.smooth

        blueLinePlot.shouldFill = false
        blueLinePlot.fillType = ScrollableGraphViewFillType.solid
        blueLinePlot.fillColor = UIColor.white.withAlphaComponent(0.8)

        blueLinePlot.adaptAnimationType = ScrollableGraphViewAnimationType.elastic

        // Customise the reference lines.
        let referenceLines = ReferenceLines()

        referenceLines.referenceLineLabelFont = UIFont(name: "Hansief", size: 11)!
        referenceLines.referenceLineColor = UIColor.clear
        referenceLines.referenceLineLabelColor = UIColor(named: "darkGrayColor")!

        referenceLines.dataPointLabelColor = UIColor(named: "darkGrayColor")!
        referenceLines.dataPointLabelFont = UIFont(name: "Hansief", size: 12)!

        
        // All other graph customisation is done in Interface Builder,
        // e.g, the background colour would be set in interface builder rather than in code.
        graphView.backgroundFillColor = UIColor.clear
        graphView.dataPointSpacing = self.view.frame.size.width / 6 - 3

        // Add everything to the graph.
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.addPlot(plot: blueLinePlot)
    }
    
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        return plotOneData[pointIndex]
    }
    
    func label(atIndex pointIndex: Int) -> String {
        let months = [LocaleUtils.sharedInstance.get("enero.short"),
                      LocaleUtils.sharedInstance.get("febrero.short"),
                      LocaleUtils.sharedInstance.get("marzo.short"),
                      LocaleUtils.sharedInstance.get("abril.short"),
                      LocaleUtils.sharedInstance.get("mayo.short"),
                      LocaleUtils.sharedInstance.get("junio.short"),
                      LocaleUtils.sharedInstance.get("julio.short"),
                      LocaleUtils.sharedInstance.get("agosto.short"),
                      LocaleUtils.sharedInstance.get("septiembre.short"),
                      LocaleUtils.sharedInstance.get("octubre.short"),
                      LocaleUtils.sharedInstance.get("noviembre.short"),
                      LocaleUtils.sharedInstance.get("diciembre.short")]
        
        var dateComponent = DateComponents()
        dateComponent.month = pointIndex - 6
        let futureDate = Calendar.current.date(byAdding: dateComponent, to: Date())
        let monthInt = Calendar.current.component(.month, from: futureDate!)
        return months[monthInt-1]
      
    }
    
    func numberOfPoints() -> Int {
        return numberOfItems
    }
}

extension TicketsView: TicketsViewProtocol {
    func reloadTicketsData() {
        if TicketDataManager.sharedInstance.getUserTickets().count > 0 || AuthDataManager.sharedInstance.getAhorros().count > 0 {
            self.emptyView.isHidden = true
            self.emptyViewHeight.constant = 0
            self.ticketsTableView.isHidden = false
            self.ticketAhorroView.isHidden = false
            self.ticketAhorroViewHeight.constant = 500
            self.ticketsTableViewHeight.constant = CGFloat(150 * (TicketDataManager.sharedInstance.getUserTickets().count > 6 ? 6 : TicketDataManager.sharedInstance.getUserTickets().count))
            view.hideSkeleton(transition: .crossDissolve(0.25))
            self.ticketsTableView.reloadData()
            
            // SERVICIO DE AHORRO
            let ahorros: [Ahorro] = AuthDataManager.sharedInstance.getAhorros()
            let monthInt = Calendar.current.component(.month, from: Date())
            var totalAhorro: Float = 0
            if ahorros.count > 0 {
                for ahorro in ahorros {
                    totalAhorro = totalAhorro + ahorro.importeAhorroBonos.value! + ahorro.importeAhorroPromos.value! + ahorro.importeAhorroVales.value!
                    let calenderDate = Calendar.current.dateComponents([.month], from: ahorro.fecha!)
                    if monthInt - calenderDate.month! >= 0 {
                        self.plotOneData[5 - (monthInt - calenderDate.month! - 1)] = Double(ahorro.importeAhorroBonos.value! + ahorro.importeAhorroPromos.value! + ahorro.importeAhorroVales.value!)
                    }
                    else {
                        self.plotOneData[5 - ((monthInt + 12) - calenderDate.month! - 1)] = Double(ahorro.importeAhorroBonos.value! + ahorro.importeAhorroPromos.value! + ahorro.importeAhorroVales.value!)
                    }
                }

                let s = NSString(format: "%.2f", totalAhorro as CVarArg)
                self.ticketAhorroNumber.text = s.components(separatedBy: ".")[0]
                self.ticketAhorroDecimal.text = s.components(separatedBy: ".")[1] != "00" ? String(format: "'%@€", s.components(separatedBy: ".")[1]) : "€"
                
                if NetworkUtils.sharedInstance.isConnected() {
                    self.ticketScrollableGraphView.dataSource = self
                    self.ticketScrollableGraphView.reload()
                    
                }
                
            }
            else {
                self.ticketAhorroView.isHidden = true
                self.ticketAhorroViewHeight.constant = 0
            }
        }
        else {
            self.emptyView.isHidden = false
            self.emptyViewHeight.constant = self.view.frame.size.height - 280
            self.ticketsTableViewHeight.constant = 0
            self.ticketsTableView.isHidden = true
            self.ticketAhorroView.isHidden = true
            self.ticketAhorroViewHeight.constant = 0
        }
    }
    
    
    func retryOldValueTicketState() {
        if AuthDataManager.sharedInstance.getUserData().associatedCliente?.clienteBasico?.ticketDigital.value != nil {
            digitalTicketSwitch.isOn = ((AuthDataManager.sharedInstance.getUserData().associatedCliente?.clienteBasico?.ticketDigital.value!) == true)
        }
        else {
            digitalTicketSwitch.isOn = false
        }
    }
    
    
}

extension TicketsView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ticket: Ticket = TicketDataManager.sharedInstance.getUserTickets()[indexPath.row]
        self.presenter?.goToDetail(ticket: ticket)
    }
}

extension TicketsView: SkeletonTableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TicketDataManager.sharedInstance.getUserTickets().count > 6 ? 6 : TicketDataManager.sharedInstance.getUserTickets().count
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "ticketListCell"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketListCell", for: indexPath) as! TicketListViewCell
        let ticket: Ticket = TicketDataManager.sharedInstance.getUserTickets()[indexPath.row]
        if ticket.associatedTienda != nil {
            cell.ticketAddress.text = ticket.associatedTienda?.direccionTienda
            cell.ticketDayPosition.constant = 37
            cell.ticketStoreIcon.isHidden = false
        }
        else {
            cell.ticketAddress.text = ""
            cell.ticketDayPosition.constant = 16
            cell.ticketStoreIcon.isHidden = true
        }
        
        cell.tag = indexPath.row
        cell.ticketDay.text = FormatUtils.sharedInstance.dateToTicketFormat(date: ticket.fecha!).uppercased()
        let importe = NSString(format: "%.2f", ticket.importeTicket.value!)
        cell.ticketValueNumber.text = importe.components(separatedBy: ".")[0]
        cell.ticketValueDecimal.text = importe.components(separatedBy: ".")[1] != "00" ? String(format: "'%@€", importe.components(separatedBy: ".")[1]) : "€"
        cell.ticketHour.text = String(format: "%@H", FormatUtils.sharedInstance.getHourFromDate(date: ticket.fecha!))
        
        cell.ticketDetailButton.setTitle(LocaleUtils.sharedInstance.get("ticket.detail.title"), for: .normal)
        cell.ticketProductsButton.setTitle(LocaleUtils.sharedInstance.get("ticket.products.title"), for: .normal)
        if ticket.importeAhorro.value! > Float(0) {
            cell.ticketAhorroTitle.text = LocaleUtils.sharedInstance.get("ticket.ahorro.title")
            cell.ticketAhorroView.isHidden = false
            cell.ticketAhorroViewWidth.constant = 95
            cell.ticketAhorroValue.text = ("\(ticket.importeAhorro.value!.rounded.clean2Value)€").replacingOccurrences(of: ".", with: "'")
            if ticket.importeAcumulas.value! > Float(0) {
                cell.ticketAcumulaTitle.text = LocaleUtils.sharedInstance.get("ticket.acumulas.title")
                cell.ticketAcumulaView.isHidden = false
                cell.ticketAcumulaViewWidth.constant = 95
                cell.ticketAcumulaValue.text = ("\(ticket.importeAcumulas.value!.rounded.clean2Value)€").replacingOccurrences(of: ".", with: "'")
            }
            else {
                cell.ticketAcumulaView.isHidden = true
                cell.ticketAcumulaViewWidth.constant = 0
            }
        }
        else {
            cell.ticketAhorroView.isHidden = true
            cell.ticketAhorroViewWidth.constant = 0
            if ticket.importeAcumulas.value! > Float(0) {
                cell.ticketAcumulaTitle.text = LocaleUtils.sharedInstance.get("ticket.acumulas.title")
                cell.ticketAcumulaView.isHidden = false
                cell.ticketAcumulaViewWidth.constant = 95
                cell.ticketAcumulaValue.text = ("\(ticket.importeAcumulas.value!.rounded.clean2Value)€").replacingOccurrences(of: ".", with: "'")
            }
            else {
                cell.ticketAcumulaView.isHidden = true
                cell.ticketAcumulaViewWidth.constant = 0
            }
        }
        
        cell.seeTicketDetailAction = {[unowned self] in
            self.presenter?.goToDetail(ticket: ticket)
        }
        cell.seeTicketProductsAction = {[unowned self] in
            self.presenter?.goToProducts(ticket: ticket)
        }
        return cell
    }
}

extension TicketsView: ModalDelegate {
    func reloadTicketState() {
        if AuthDataManager.sharedInstance.getUserData().associatedCliente?.clienteBasico?.ticketDigital.value != nil {
            digitalTicketSwitch.isOn = ((AuthDataManager.sharedInstance.getUserData().associatedCliente?.clienteBasico?.ticketDigital.value!) == true)
        }
        else {
            digitalTicketSwitch.isOn = false
        }
    }
}
